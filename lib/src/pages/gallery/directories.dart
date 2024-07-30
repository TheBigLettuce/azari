// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/app_info.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/pages/anime/anime.dart";
import "package:azari/src/pages/anime/info_base/always_loading_anime_mixin.dart";
import "package:azari/src/pages/gallery/blacklisted_directories.dart";
import "package:azari/src/pages/gallery/callback_description.dart";
import "package:azari/src/pages/gallery/directories_actions.dart" as actions;
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home.dart";
import "package:azari/src/plugs/gallery.dart";
import "package:azari/src/plugs/gallery/android/android_api_directories.dart";
import "package:azari/src/plugs/gallery/android/api.g.dart";
import "package:azari/src/plugs/gallery_management_api.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/segment_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";

class GalleryDirectories extends StatefulWidget {
  const GalleryDirectories({
    super.key,
    this.callback,
    this.nestedCallback,
    this.procPop,
    this.wrapGridPage = false,
    this.showBackButton = false,
    this.providedApi,
    required this.db,
    required this.l10n,
  }) : assert(!(callback != null && nestedCallback != null));

  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final bool showBackButton;
  final void Function(bool)? procPop;
  final bool wrapGridPage;

  final GalleryAPIDirectories? providedApi;
  final AppLocalizations l10n;

  final DbConn db;

  static String segmentCell(
    String name,
    String bucketId,
    DirectoryTagService directoryTag,
  ) {
    for (final booru in Booru.values) {
      if (booru.url == name) {
        return "Booru";
      }
    }

    final dirTag = directoryTag.get(bucketId);
    if (dirTag != null) {
      return dirTag;
    }

    return name.split(" ").first.toLowerCase();
  }

  @override
  State<GalleryDirectories> createState() => _GalleryDirectoriesState();
}

class _GalleryDirectoriesState extends State<GalleryDirectories> {
  WatchableGridSettingsData get gridSettings =>
      widget.db.gridSettings.directories;
  DirectoryMetadataService get directoryMetadata => widget.db.directoryMetadata;
  DirectoryTagService get directoryTags => widget.db.directoryTags;
  FavoriteFileService get favoriteFiles => widget.db.favoriteFiles;
  BlacklistedDirectoryService get blacklistedDirectories =>
      widget.db.blacklistedDirectories;

  late final StreamSubscription<SettingsData?> settingsWatcher;
  late final StreamSubscription<MiscSettingsData?> miscSettingsWatcher;
  late final StreamSubscription<void> blacklistedWatcher;
  late final StreamSubscription<void> directoryTagWatcher;
  late final StreamSubscription<void> favoritesWatcher;

  late final AppLifecycleListener lifecycleListener;

  MiscSettingsData miscSettings = MiscSettingsService.db().current;

  int galleryVersion = 0;

  late final ChainedFilterResourceSource<int, GalleryDirectory> filter;

  late final GridSkeletonState<GalleryDirectory> state = GridSkeletonState();

  final galleryPlug = chooseGalleryPlug();

  late final api = widget.providedApi ??
      galleryPlug.galleryApi(
        widget.db.blacklistedDirectories,
        widget.db.directoryTags,
        l10n: widget.l10n,
      );

  bool isThumbsLoading = false;

  final searchTextController = TextEditingController();
  final searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    galleryPlug.version.then((value) => galleryVersion = value);

    lifecycleListener = AppLifecycleListener(
      onShow: () {
        galleryPlug.version.then((value) {
          if (value != galleryVersion) {
            galleryVersion = value;
            _refresh();
          }
        });
      },
    );

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;
      setState(() {});
    });

    miscSettingsWatcher = miscSettings.s.watch((s) {
      miscSettings = s!;

      setState(() {});
    });

    directoryTagWatcher = directoryMetadata.watch((s) {
      api.source.backingStorage.addAll([]);
    });

    blacklistedWatcher = blacklistedDirectories.backingStorage.watch((_) {
      api.source.clearRefresh();
    });

    favoritesWatcher = favoriteFiles.watch((_) {
      api.source.clearRefresh();
      setState(() {});
    });

    filter = ChainedFilterResourceSource(
      api.source,
      ListStorage(),
      filter: (cells, mode, sorting, end, [data]) => (
        cells.where(
          (e) =>
              e.name.contains(searchTextController.text) ||
              e.tag.contains(searchTextController.text),
        ),
        null
      ),
      allowedFilteringModes: const {},
      allowedSortingModes: const {},
      initialFilteringMode: FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    if (widget.providedApi == null) {
      api.trashCell.refresh();
      api.source.clearRefresh();
    }
  }

  @override
  void dispose() {
    favoritesWatcher.cancel();
    directoryTagWatcher.cancel();
    blacklistedWatcher.cancel();
    settingsWatcher.cancel();
    miscSettingsWatcher.cancel();
    searchTextController.dispose();

    filter.destroy();

    if (widget.providedApi == null) {
      api.close();
    }

    searchFocus.dispose();
    state.dispose();
    lifecycleListener.dispose();

    super.dispose();
  }

  void _refresh() {
    api.trashCell.refresh();
    api.source.clearRefresh();
    galleryPlug.version.then((value) => galleryVersion = value);
  }

  String _segmentCell(GalleryDirectory cell) => GalleryDirectories.segmentCell(
        cell.name,
        cell.bucketId,
        directoryTags,
      );

  Segments<GalleryDirectory> _makeSegments(BuildContext context) {
    return Segments(
      widget.l10n.segmentsUncategorized,
      injectedLabel: widget.callback != null || widget.nestedCallback != null
          ? widget.l10n.suggestionsLabel
          : widget.l10n.segmentsSpecial,
      displayFirstCellInSpecial:
          widget.callback != null || widget.nestedCallback != null,
      caps: directoryMetadata.caps(widget.l10n.segmentsSpecial),
      segment: _segmentCell,
      injectedSegments: [
        if (favoriteFiles.isNotEmpty())
          SyncCell(
            galleryPlug.makeGalleryDirectory(
              bucketId: "favorites",
              name: widget.l10n.galleryDirectoriesFavorites,
              tag: "",
              volumeName: "",
              relativeLoc: "",
              lastModified: 0,
              thumbFileId: miscSettings.favoritesThumbId != 0
                  ? miscSettings.favoritesThumbId
                  : favoriteFiles.thumbnail,
            ),
          ),
        api.trashCell,
      ],
      onLabelPressed: widget.callback != null && !widget.callback!.joinable
          ? null
          : (label, children) => actions.joinedDirectoriesFnc(
                context,
                label,
                children,
                api,
                widget.nestedCallback,
                GlueProvider.generateOf(context),
                _segmentCell,
                directoryMetadata,
                directoryTags,
                favoriteFiles,
                widget.db.localTags,
                widget.l10n,
              ),
    );
  }

  Future<void Function(BuildContext)?> _addToGroup(
    BuildContext context,
    List<GalleryDirectory> selected,
    String value,
    bool toPin,
    AppLocalizations l10n,
  ) async {
    final requireAuth = <GalleryDirectory>[];
    final noAuth = <GalleryDirectory>[];

    for (final e in selected) {
      final m = directoryMetadata.get(_segmentCell(e));
      if (m != null && m.requireAuth) {
        requireAuth.add(e);
      } else {
        noAuth.add(e);
      }
    }

    if (noAuth.isEmpty &&
        requireAuth.isNotEmpty &&
        AppInfo().canAuthBiometric) {
      final success = await LocalAuthentication()
          .authenticate(localizedReason: l10n.changeGroupReason);
      if (!success) {
        return null;
      }
    }

    if (value.isEmpty) {
      directoryTags.delete(
        (noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth)
            .map((e) => e.bucketId),
      );
    } else {
      directoryTags.add(
        (noAuth.isEmpty && requireAuth.isNotEmpty ? requireAuth : noAuth)
            .map((e) => e.bucketId),
        value,
      );

      if (toPin) {
        if (await directoryMetadata.canAuth(
          value,
          l10n.unstickyStickyDirectory,
        )) {
          directoryMetadata.getOrCreate(value).copyBools(sticky: true).save();
        }
      }
    }

    _refresh();

    if (noAuth.isNotEmpty && requireAuth.isNotEmpty) {
      return (BuildContext context) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.directoriesAuthMessage),
            action: SnackBarAction(
              label: l10n.authLabel,
              onPressed: () async {
                final success = await LocalAuthentication()
                    .authenticate(localizedReason: l10n.changeGroupReason);
                if (!success) {
                  return;
                }

                if (value.isEmpty) {
                  directoryTags.delete(requireAuth.map((e) => e.bucketId));
                } else {
                  directoryTags.add(
                    requireAuth.map((e) => e.bucketId),
                    value,
                  );
                }

                _refresh();
              },
            ),
          ),
        );
      };
    } else {
      return null;
    }
  }

  // ignore: use_setters_to_change_properties
  void _add(GridSettingsData d) => gridSettings.current = d;

  Future<List<BooruTag>> _completeDirectoryNameTag(String str) {
    final m = <String, void>{};

    return Future.value(
      api.source.backingStorage
          .map(
            (e) {
              if (e.tag.isNotEmpty &&
                  e.tag.contains(str) &&
                  !m.containsKey(e.tag)) {
                m[e.tag] = null;
                return e.tag;
              }

              if (e.name.startsWith(str) && !m.containsKey(e.name)) {
                m[e.name] = null;

                return e.name;
              } else {
                return null;
              }
            },
          )
          .where((e) => e != null)
          .take(15)
          .map((e) => BooruTag(e!, -1))
          .toList(),
    );
  }

  Widget child(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GridPopScope(
      filter: filter,
      rootNavigatorPopCond: widget.nestedCallback != null,
      searchTextController: searchTextController,
      rootNavigatorPop: widget.procPop,
      child: GridFrame<GalleryDirectory>(
        key: state.gridKey,
        slivers: [
          if (widget.nestedCallback != null)
            SliverToBoxAdapter(
              child: _LatestImagesWidget(
                db: widget.db,
                parent: api,
                callback: widget.nestedCallback!,
              ),
            ),
          SegmentLayout(
            segments: _makeSegments(context),
            gridSeed: 1,
            suggestionPrefix: widget.callback?.suggestFor ?? const [],
            storage: filter.backingStorage,
            progress: filter.progress,
            localizations: widget.l10n,
          ),
        ],
        functionality: GridFunctionality(
          selectionGlue: GlueProvider.generateOf(context)(),
          registerNotifiers: (child) => DirectoriesDataNotifier(
            api: api,
            nestedCallback: widget.nestedCallback,
            callback: widget.callback,
            segmentFnc: _segmentCell,
            child: child,
          ),
          source: filter,
          settingsButton: GridSettingsButton(
            add: _add,
            watch: gridSettings.watch,
          ),
          search: BarSearchWidget.fromFilter(
            filter,
            textEditingController: searchTextController,
            complete: _completeDirectoryNameTag,
            focus: searchFocus,
            trailingItems: [
              if (widget.callback != null)
                IconButton(
                  onPressed: () => GalleryManagementApi.current()
                      .chooseDirectory(l10n, temporary: true)
                      .then((value) {
                    widget.callback!(
                      chosen: value!.$2,
                      volumeName: "",
                      bucketId: "",
                      newDir: true,
                    );
                  }).onError((e, trace) {
                    Logger.root
                        .severe("new folder in android_directories", e, trace);
                  }).whenComplete(() {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }),
                  icon: const Icon(Icons.create_new_folder_outlined),
                )
              else
                IconButton(
                  onPressed: () {
                    GallerySubPage.selectOf(
                      context,
                      GallerySubPage.blacklisted,
                    );
                  },
                  icon: const Icon(Icons.folder_off_outlined),
                ),
            ],
          ),
        ),
        description: GridDescription(
          actions: widget.callback != null || widget.nestedCallback != null
              ? <GridAction<GalleryDirectory>>[
                  if (widget.callback == null || widget.callback!.joinable)
                    actions.joinedDirectories(
                      context,
                      api,
                      widget.nestedCallback,
                      GlueProvider.generateOf(context),
                      _segmentCell,
                      directoryMetadata,
                      directoryTags,
                      favoriteFiles,
                      widget.db.localTags,
                      widget.l10n,
                    ),
                ]
              : <GridAction<GalleryDirectory>>[
                  actions.addToGroup(
                    context,
                    (selected) {
                      final t = selected.first.tag;
                      for (final e in selected.skip(1)) {
                        if (t != e.tag) {
                          return null;
                        }
                      }

                      return t;
                    },
                    (s, v, t) => _addToGroup(context, s, v, t, l10n),
                    true,
                    completeDirectoryNameTag: _completeDirectoryNameTag,
                  ),
                  actions.blacklist(
                    context,
                    _segmentCell,
                    directoryMetadata,
                    blacklistedDirectories,
                    widget.l10n,
                  ),
                  actions.joinedDirectories(
                    context,
                    api,
                    widget.nestedCallback,
                    GlueProvider.generateOf(context),
                    _segmentCell,
                    directoryMetadata,
                    directoryTags,
                    favoriteFiles,
                    widget.db.localTags,
                    widget.l10n,
                  ),
                ],
          footer: widget.callback?.preview ?? widget.nestedCallback?.preview,
          keybindsDescription: widget.l10n.androidGKeybindsDescription,
          gridSeed: state.gridSeed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.callback != null || widget.nestedCallback != null) {
      return GridConfiguration(
        watch: gridSettings.watch,
        child: widget.wrapGridPage
            ? WrapGridPage(
                addScaffold: widget.callback != null,
                child: Builder(
                  builder: child,
                ),
              )
            : child(context),
      );
    }

    return switch (GallerySubPage.of(context)) {
      GallerySubPage.gallery => GridConfiguration(
          watch: gridSettings.watch,
          child: widget.wrapGridPage
              ? WrapGridPage(
                  addScaffold: widget.callback != null,
                  child: Builder(
                    builder: child,
                  ),
                )
              : child(context),
        ),
      GallerySubPage.blacklisted => DirectoriesDataNotifier(
          api: api,
          nestedCallback: widget.nestedCallback,
          callback: widget.callback,
          segmentFnc: _segmentCell,
          child: GridPopScope(
            searchTextController: null,
            filter: null,
            rootNavigatorPop: widget.procPop,
            child: BlacklistedDirectories(
              popScope: widget.procPop ??
                  (_) =>
                      GallerySubPage.selectOf(context, GallerySubPage.gallery),
              generate: GlueProvider.generateOf(context),
              db: widget.db,
            ),
          ),
        ),
    };
  }
}

class _LatestImagesWidget extends StatefulWidget {
  const _LatestImagesWidget({
    // super.key,
    required this.db,
    required this.parent,
    required this.callback,
  });

  final DbConn db;
  final GalleryAPIDirectories parent;
  final CallbackDescriptionNested callback;

  @override
  State<_LatestImagesWidget> createState() => __LatestImagesWidgetState();
}

class __LatestImagesWidgetState extends State<_LatestImagesWidget> {
  late final StreamSubscription<void> _directoryCapsChanged;

  late final filesApi = GalleryAPIFiles.fake(
    widget.db,
    clearRefresh: () {
      final c = <String, DirectoryMetadata>{};

      return GalleryHostApi().getPicturesDirectly(null, 20, true).then((l) {
        final ll = _fromDirectoryFileFiltered(l, c);

        if (ll.length < 10) {
          return GalleryHostApi()
              .getPicturesDirectly(null, 20, true)
              .then((e) => ll + _fromDirectoryFileFiltered(l, c));
        }

        return ll;
      });
    },
    parent: widget.parent,
  );

  late final gridSelection = GridSelection<GalleryFile>(
    const [],
    SelectionGlue.empty(context),
    noAppBar: true,
    source: filesApi.source.backingStorage,
  );

  final focus = FocusNode();

  late final GridFunctionality<GalleryFile> functionality = GridFunctionality(
    registerNotifiers: (child) => GridExtrasNotifier(
      data: GridExtrasData(
        gridSelection,
        functionality,
        const GridDescription<GalleryFile>(
          actions: [],
          gridSeed: 0,
          keybindsDescription: "",
        ),
        focus,
      ),
      child: FilesDataNotifier(
        api: filesApi,
        nestedCallback: widget.callback,
        child: child,
      ),
    ),
    source: filesApi.source,
    selectionGlue: SelectionGlue.empty(context),
  );

  final ValueNotifier<bool> scrollNotifier = ValueNotifier(false);
  final controller = ScrollController();

  List<GalleryFile> _fromDirectoryFileFiltered(
    List<DirectoryFile?> l,
    Map<String, DirectoryMetadata> c,
  ) {
    return l
        .where(
          (e) => GalleryFilesPageType.filterAuthBlur(
            c,
            e,
            widget.db.directoryTags,
            widget.db.directoryMetadata,
          ),
        )
        .map(
          (e) => e!.toAndroidFile(
            widget.db.localTags.get(e.name).fold({}, (map, e) {
              map[e] = null;

              return map;
            }),
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();

    _directoryCapsChanged = widget.db.directoryMetadata.watch((_) {
      filesApi.source.clearRefresh();
    });
  }

  @override
  void dispose() {
    _directoryCapsChanged.cancel();
    focus.dispose();
    filesApi.close();
    scrollNotifier.dispose();
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GridExtrasNotifier(
      data: GridExtrasData(
        gridSelection,
        functionality,
        const GridDescription<GalleryFile>(
          actions: [],
          gridSeed: 0,
          keybindsDescription: "",
        ),
        focus,
      ),
      child: GridScrollNotifier(
        scrollNotifier: scrollNotifier,
        controller: controller,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: theme.colorScheme.surfaceContainerLow.withOpacity(0.8),
            ),
            child: FadingPanel(
              label: l10n.lastAdded,
              source: filesApi.source,
              enableHide: false,
              horizontalPadding: _LatestList.listPadding,
              childSize: _LatestList.size,
              child: _LatestList(
                source: filesApi.source,
                functionality: functionality,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestList extends StatefulWidget {
  const _LatestList({
    // super.key,
    required this.source,
    required this.functionality,
  });

  final ResourceSource<int, GalleryFile> source;
  final GridFunctionality<GalleryFile> functionality;

  static const size = Size(140 / 1.5, 140 + 16);
  static const listPadding = EdgeInsets.symmetric(horizontal: 12);

  @override
  State<_LatestList> createState() => __LatestListState();
}

class __LatestListState extends State<_LatestList> {
  ResourceSource<int, GalleryFile> get source => widget.source;

  late final StreamSubscription<void> subscription;

  @override
  void initState() {
    super.initState();

    subscription = source.backingStorage.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CellProvider<GalleryFile>(
      getCell: source.forIdxUnsafe,
      child: SizedBox(
        width: double.infinity,
        height: _LatestList.size.height,
        child: WrapFutureRestartable<int>(
          bottomSheetVariant: true,
          placeholder: const ShimmerPlaceholdersHorizontal(
            childSize: _LatestList.size,
            padding: _LatestList.listPadding,
          ),
          newStatus: () {
            if (source.backingStorage.isNotEmpty) {
              return Future.value(source.backingStorage.count);
            }

            return source.clearRefresh();
          },
          builder: (context, _) {
            return ListView.builder(
              padding: _LatestList.listPadding,
              scrollDirection: Axis.horizontal,
              itemCount: source.backingStorage.count,
              itemBuilder: (context, i) {
                final cell = source.backingStorage[i];

                return InkWell(
                  onTap: () {
                    cell.onPress(context, widget.functionality, cell, i);
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: _LatestList.size.width,
                    child: GridCell(
                      cell: cell,
                      hideTitle: false,
                      imageAlign: Alignment.topCenter,
                      overrideDescription: const CellStaticData(
                        ignoreSwipeSelectGesture: true,
                        alignTitleToTopLeft: true,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class GridPopScope extends StatefulWidget {
  const GridPopScope({
    super.key,
    this.rootNavigatorPop,
    required this.searchTextController,
    required this.filter,
    required this.child,
    this.rootNavigatorPopCond = false,
  });

  final TextEditingController? searchTextController;
  final void Function(bool)? rootNavigatorPop;
  final bool rootNavigatorPopCond;
  final ChainedFilterResourceSource<dynamic, dynamic>? filter;
  final Widget child;

  @override
  State<GridPopScope> createState() => _GridPopScopeState();
}

class _GridPopScopeState extends State<GridPopScope> {
  late final StreamSubscription<void>? _watcher;

  @override
  void initState() {
    super.initState();

    _watcher = widget.filter?.backingStorage.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _watcher?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glue = GlueProvider.generateOf(context)();

    return PopScope(
      canPop: widget.rootNavigatorPop != null
          ? widget.rootNavigatorPopCond
          : false ||
              !glue.isOpen() &&
                  (widget.searchTextController == null ||
                      widget.searchTextController!.text.isEmpty) &&
                  (widget.filter == null ||
                      widget.filter!.allowedFilteringModes.isEmpty ||
                      (widget.filter!.allowedFilteringModes
                              .contains(FilteringMode.noFilter) &&
                          widget.filter!.filteringMode ==
                              FilteringMode.noFilter)),
      onPopInvokedWithResult: (didPop, _) {
        if (glue.isOpen()) {
          glue.updateCount(0);

          return;
        } else if (widget.searchTextController != null &&
            widget.searchTextController!.text.isNotEmpty) {
          widget.searchTextController!.text = "";
          widget.filter?.clearRefresh();

          return;
        } else if (widget.filter != null &&
            widget.filter!.allowedFilteringModes
                .contains(FilteringMode.noFilter) &&
            widget.filter!.filteringMode != FilteringMode.noFilter) {
          widget.filter!.filteringMode = FilteringMode.noFilter;
        }

        widget.rootNavigatorPop?.call(didPop);
      },
      child: widget.child,
    );
  }
}

class DirectoriesDataNotifier extends InheritedWidget {
  const DirectoriesDataNotifier({
    super.key,
    required this.api,
    required this.nestedCallback,
    required this.callback,
    required this.segmentFnc,
    required super.child,
  });

  final GalleryAPIDirectories api;
  final CallbackDescription? callback;
  final CallbackDescriptionNested? nestedCallback;
  final String Function(GalleryDirectory cell) segmentFnc;

  static (
    GalleryAPIDirectories,
    CallbackDescription?,
    CallbackDescriptionNested?,
    String Function(GalleryDirectory cell),
  ) of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<DirectoriesDataNotifier>();

    return (
      widget!.api,
      widget.callback,
      widget.nestedCallback,
      widget.segmentFnc,
    );
  }

  @override
  bool updateShouldNotify(DirectoriesDataNotifier oldWidget) =>
      api != oldWidget.api ||
      callback != oldWidget.callback ||
      nestedCallback != oldWidget.nestedCallback ||
      segmentFnc != oldWidget.segmentFnc;
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/resource_source/chained_filter.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/gallery/gallery_directories_actions.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/blacklisted_page.dart";
import "package:gallery/src/pages/more/favorite_booru_actions.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/segment_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";
import "package:local_auth/local_auth.dart";

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

  static const _log = LogTarget.gallery;

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
    });

    filter = ChainedFilterResourceSource(
      api.source,
      ListStorage(),
      filter: (cells, mode, sorting, end, [data]) => (
        cells.where((e) => e.name.contains(searchTextController.text)),
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
            GalleryDirectory.forPlatform(
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
          : (label, children) =>
              SystemGalleryDirectoriesActions.joinedDirectoriesFnc(
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

    if (noAuth.isEmpty && requireAuth.isNotEmpty && canAuthBiometric) {
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
                    _log.logDefaultImportant(
                      "new folder in android_directories".errorMessage(e),
                      trace,
                    );
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
              ? [
                  if (widget.callback == null || widget.callback!.joinable)
                    SystemGalleryDirectoriesActions.joinedDirectories(
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
              : [
                  FavoritesActions.addToGroup(
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
                  ),
                  SystemGalleryDirectoriesActions.blacklist(
                    context,
                    _segmentCell,
                    directoryMetadata,
                    blacklistedDirectories,
                    widget.l10n,
                  ),
                  SystemGalleryDirectoriesActions.joinedDirectories(
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
            child: BlacklistedPage(
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
      onPopInvoked: (didPop) {
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

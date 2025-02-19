// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/app_info.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/pages/gallery/blacklisted_directories.dart";
import "package:azari/src/pages/gallery/directories_actions.dart" as actions;
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/pages/search/gallery/gallery_search_page.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/fading_panel.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_fab_type.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/segment_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:azari/src/widgets/shimmer_placeholders.dart";
import "package:azari/src/widgets/wrap_future_restartable.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";

class DirectoriesPage extends StatefulWidget {
  const DirectoriesPage({
    super.key,
    required this.l10n,
    required this.gridSettings,
    required this.directoryMetadata,
    required this.directoryTags,
    required this.favoritePosts,
    required this.blacklistedDirectories,
    required this.miscSettingsService,
    required this.settingsService,
    required this.gridDbs,
    required this.localTagsService,
    required this.galleryService,
    this.callback,
    this.wrapGridPage = false,
    this.showBackButton = false,
    this.providedApi,
    this.procPop,
  });

  final bool showBackButton;
  final bool wrapGridPage;

  final void Function(bool)? procPop;

  final GalleryReturnCallback? callback;

  final Directories? providedApi;
  final AppLocalizations l10n;

  final DirectoryMetadataService? directoryMetadata;
  final DirectoryTagService? directoryTags;
  final FavoritePostSourceService? favoritePosts;
  final BlacklistedDirectoryService? blacklistedDirectories;
  final LocalTagsService? localTagsService;
  final MiscSettingsService? miscSettingsService;

  final GalleryService galleryService;
  final GridDbService gridDbs;
  final GridSettingsService gridSettings;
  final SettingsService settingsService;

  static bool hasServicesRequired(Services db) =>
      db.get<GridSettingsService>() != null &&
      db.get<GridDbService>() != null &&
      db.get<GalleryService>() != null;

  static String segmentCell(
    String name,
    String bucketId,
    DirectoryTagService? directoryTag,
  ) {
    for (final booru in Booru.values) {
      if (booru.url == name) {
        return "Booru";
      }
    }

    final dirTag = directoryTag?.get(bucketId);
    if (dirTag != null) {
      return dirTag;
    }

    return name.split(" ").first.toLowerCase();
  }

  static Future<void> open(
    BuildContext context, {
    required AppLocalizations l10n,
    bool showBackButton = false,
    bool wrapGridPage = false,
    void Function(bool)? procPop,
    GalleryReturnCallback? callback,
    Directories? providedApi,
  }) {
    final db = Services.of(context);
    final (gridSettings, gridDbs, galleryService) = (
      db.get<GridSettingsService>(),
      db.get<GridDbService>(),
      db.get<GalleryService>(),
    );
    if (gridSettings == null || gridDbs == null || galleryService == null) {
      // TODO: change
      showSnackbar(context, "Gallery functionality isn't available");

      return Future.value();
    }

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => DirectoriesPage(
          l10n: l10n,
          showBackButton: showBackButton,
          wrapGridPage: wrapGridPage,
          procPop: procPop,
          callback: callback,
          providedApi: providedApi,
          gridSettings: gridSettings,
          gridDbs: gridDbs,
          galleryService: galleryService,
          directoryMetadata: db.get<DirectoryMetadataService>(),
          directoryTags: db.get<DirectoryTagService>(),
          favoritePosts: db.get<FavoritePostSourceService>(),
          blacklistedDirectories: db.get<BlacklistedDirectoryService>(),
          miscSettingsService: db.get<MiscSettingsService>(),
          localTagsService: db.get<LocalTagsService>(),
          settingsService: db.require<SettingsService>(),
        ),
      ),
    );
  }

  @override
  State<DirectoriesPage> createState() => _DirectoriesPageState();
}

class _DirectoriesPageState extends State<DirectoriesPage>
    with CommonGridData<Post, DirectoriesPage>, MiscSettingsWatcherMixin {
  WatchableGridSettingsData get gridSettings => widget.gridSettings.directories;
  DirectoryMetadataService? get directoryMetadata => widget.directoryMetadata;
  DirectoryTagService? get directoryTags => widget.directoryTags;
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;
  BlacklistedDirectoryService? get blacklistedDirectories =>
      widget.blacklistedDirectories;
  LocalTagsService? get localTagsService => widget.localTagsService;

  GalleryService get galleryService => widget.galleryService;
  GridDbService get gridDbs => widget.gridDbs;

  @override
  MiscSettingsService? get miscSettingsService => widget.miscSettingsService;

  @override
  SettingsService get settingsService => widget.settingsService;

  late final StreamSubscription<void>? blacklistedWatcher;
  late final StreamSubscription<void>? directoryTagWatcher;

  late final AppLifecycleListener lifecycleListener;

  int galleryVersion = 0;

  late final ChainedFilterResourceSource<int, Directory> filter;

  late final api = widget.providedApi ??
      galleryService.open(
        l10n: widget.l10n,
        settingsService: settingsService,
        blacklistedDirectory: blacklistedDirectories,
        directoryTags: directoryTags,
        galleryTrash: galleryService.trash,
      );

  bool isThumbsLoading = false;

  final searchTextController = TextEditingController();
  final searchFocus = FocusNode(canRequestFocus: false);

  @override
  void initState() {
    super.initState();

    galleryService.version.then((value) => galleryVersion = value);

    lifecycleListener = AppLifecycleListener(
      onShow: () {
        galleryService.version.then((value) {
          if (value != galleryVersion) {
            galleryVersion = value;
            _refresh();
          }
        });
      },
    );

    watchSettings();

    directoryTagWatcher = directoryMetadata?.watch((s) {
      api.source.backingStorage.addAll([]);
    });

    blacklistedWatcher = blacklistedDirectories?.backingStorage.watch((_) {
      api.source.clearRefresh();
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
      api.trashCell?.refresh();
      api.source.clearRefresh();
    }
  }

  @override
  void dispose() {
    directoryTagWatcher!.cancel();
    blacklistedWatcher!.cancel();
    searchTextController.dispose();

    filter.destroy();

    if (widget.providedApi == null) {
      api.close();
    }

    searchFocus.dispose();
    lifecycleListener.dispose();

    super.dispose();
  }

  void _refresh() {
    api.trashCell?.refresh();
    api.source.clearRefresh();
    galleryService.version.then((value) => galleryVersion = value);
  }

  String _segmentCell(Directory cell) => DirectoriesPage.segmentCell(
        cell.name,
        cell.bucketId,
        directoryTags,
      );

  Segments<Directory> _makeSegments(
    BuildContext context, {
    required DirectoryMetadataService? directoryMetadata,
  }) {
    return Segments(
      widget.l10n.segmentsUncategorized,
      injectedLabel: widget.callback != null
          ? widget.l10n.suggestionsLabel
          : widget.l10n.segmentsSpecial,
      displayFirstCellInSpecial: widget.callback != null,
      caps: directoryMetadata?.caps(widget.l10n.segmentsSpecial) ??
          const SegmentCapability.empty(),
      segment: _segmentCell,
      injectedSegments: api.trashCell != null ? [api.trashCell!] : const [],
      onLabelPressed: widget.callback == null || widget.callback!.isFile
          ? (label, children) => actions.joinedDirectoriesFnc(
                context,
                label,
                children,
                api,
                widget.callback?.toFile,
                _segmentCell,
                widget.l10n,
                directoryMetadata: directoryMetadata,
                directoryTags: directoryTags,
                favoritePosts: favoritePosts,
                localTags: localTagsService,
              )
          : null,
    );
  }

  Future<void Function(BuildContext)?> _addToGroup(
    BuildContext context,
    List<Directory> selected,
    String value,
    bool toPin,
    AppLocalizations l10n, {
    required DirectoryMetadataService directoryMetadata,
    required DirectoryTagService directoryTags,
  }) async {
    final requireAuth = <Directory>[];
    final noAuth = <Directory>[];

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
        if (await Directory.canAuth(
          value,
          l10n.unstickyStickyDirectory,
        )) {
          directoryMetadata
              .getOrCreate(value)
              .copyBools(sticky: true)
              .maybeSave();
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
    final l10n = context.l10n();
    final navBarEvents = NavigationButtonEvents.maybeOf(context);

    return GridPopScope(
      filter: filter,
      rootNavigatorPopCond: widget.callback?.isFile ?? false,
      searchTextController: searchTextController,
      rootNavigatorPop: widget.procPop,
      child: GridFrame<Directory>(
        key: gridKey,
        slivers: [
          if (widget.callback?.isFile ?? false)
            SliverToBoxAdapter(
              child: _LatestImagesWidget(
                selectionActions: SelectionActions.of(context),
                parent: api,
                callback: widget.callback?.toFile,
                gallerySearch: galleryService.search,
                directoryMetadata: directoryMetadata,
                directoryTags: directoryTags,
                favoritePosts: favoritePosts,
                localTagsService: localTagsService,
              ),
            ),
          SegmentLayout(
            segments:
                _makeSegments(context, directoryMetadata: directoryMetadata),
            gridSeed: 1,
            suggestionPrefix: (widget.callback?.isDirectory ?? false)
                ? widget.callback!.toDirectory.suggestFor
                : const [],
            storage: filter.backingStorage,
            progress: filter.progress,
            localizations: widget.l10n,
          ),
        ],
        functionality: GridFunctionality(
          selectionActions: SelectionActions.of(context),
          scrollingState: ScrollingStateSinkProvider.maybeOf(context),
          scrollUpOn: navBarEvents == null
              ? const []
              : [(navBarEvents, () => api.bindFiles == null)],
          registerNotifiers: (child) => DirectoriesDataNotifier(
            api: api,
            callback: widget.callback,
            segmentFnc: _segmentCell,
            child: child,
          ),
          onEmptySource: _EmptyWidget(trashCell: api.trashCell),
          source: filter,
          fab: widget.callback == null
              ? const NoGridFab()
              : const DefaultGridFab(),
          settingsButton: GridSettingsButton(
            add: _add,
            watch: gridSettings.watch,
            localizeHideNames: (context) =>
                l10n.hideNames(l10n.hideNamesDirectories),
          ),
          search: widget.callback != null
              ? BarSearchWidget.fromFilter(
                  filter,
                  textEditingController: searchTextController,
                  complete: _completeDirectoryNameTag,
                  focus: searchFocus,
                  trailingItems: [
                    if (widget.callback!.isDirectory)
                      IconButton(
                        onPressed: () => galleryService
                            .chooseDirectory(l10n, temporary: true)
                            .then((value) {
                          widget.callback!.toDirectory(
                            (
                              bucketId: "",
                              path: value!.path,
                              volumeName: "",
                            ),
                            true,
                          );
                        }).onError((e, trace) {
                          Logger.root.severe(
                            "new folder in android_directories",
                            e,
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
                )
              : RawSearchWidget(
                  (context, settingsButton, bottomWidget) {
                    final theme = Theme.of(context);

                    return SliverAppBar(
                      leading: const SizedBox.shrink(),
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarIconBrightness:
                            theme.brightness == Brightness.light
                                ? Brightness.dark
                                : Brightness.light,
                        statusBarColor:
                            theme.colorScheme.surface.withValues(alpha: 0.95),
                      ),
                      bottom: bottomWidget ??
                          const PreferredSize(
                            preferredSize: Size.zero,
                            child: SizedBox.shrink(),
                          ),
                      centerTitle: true,
                      title: IconButton(
                        onPressed: () => GallerySearchPage.open(context),
                        icon: const Icon(Icons.search_rounded),
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            GallerySubPage.selectOf(
                              context,
                              GallerySubPage.blacklisted,
                            );
                          },
                          icon: const Icon(Icons.folder_off_outlined),
                        ),
                        if (settingsButton != null) settingsButton,
                      ],
                    );
                  },
                ),
        ),
        description: GridDescription(
          actions: widget.callback != null
              ? <GridAction<Directory>>[
                  if (widget.callback?.isFile ?? false)
                    actions.joinedDirectories(
                      context,
                      api,
                      widget.callback?.toFileOrNull,
                      _segmentCell,
                      widget.l10n,
                      directoryMetadata: directoryMetadata,
                      directoryTags: directoryTags,
                      favoritePosts: favoritePosts,
                      localTags: localTagsService,
                    ),
                ]
              : <GridAction<Directory>>[
                  if (directoryMetadata != null && directoryTags != null)
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
                      (s, v, t) => _addToGroup(
                        context,
                        s,
                        v,
                        t,
                        l10n,
                        directoryMetadata: directoryMetadata!,
                        directoryTags: directoryTags!,
                      ),
                      true,
                      completeDirectoryNameTag: _completeDirectoryNameTag,
                    ),
                  if (blacklistedDirectories != null)
                    actions.blacklist(
                      context,
                      _segmentCell,
                      widget.l10n,
                      directoryMetadata: directoryMetadata,
                      blacklistedDirectory: blacklistedDirectories!,
                    ),
                  actions.joinedDirectories(
                    context,
                    api,
                    widget.callback?.toFileOrNull,
                    _segmentCell,
                    widget.l10n,
                    directoryMetadata: directoryMetadata,
                    directoryTags: directoryTags,
                    favoritePosts: favoritePosts,
                    localTags: localTagsService,
                  ),
                ],
          footer: widget.callback?.preview,
          pageName: widget.l10n.galleryLabel,
          gridSeed: gridSeed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.callback != null) {
      return GridConfiguration(
        watch: gridSettings.watch,
        child: widget.wrapGridPage
            ? WrapGridPage(
                addScaffoldAndBar: true,
                child: Builder(builder: child),
              )
            : child(context),
      );
    }

    return switch (GallerySubPage.of(context)) {
      GallerySubPage.gallery => GridConfiguration(
          watch: gridSettings.watch,
          child: widget.wrapGridPage
              ? WrapGridPage(
                  child: Builder(
                    builder: child,
                  ),
                )
              : child(context),
        ),
      GallerySubPage.blacklisted => blacklistedDirectories != null
          ? DirectoriesDataNotifier(
              api: api,
              callback: widget.callback,
              segmentFnc: _segmentCell,
              child: GridPopScope(
                searchTextController: null,
                filter: null,
                rootNavigatorPop: widget.procPop,
                child: BlacklistedDirectoriesPage(
                  popScope: widget.procPop ??
                      (_) => GallerySubPage.selectOf(
                            context,
                            GallerySubPage.gallery,
                          ),
                  settingsService: settingsService,
                  blacklistedDirectories: blacklistedDirectories!,
                ),
              ),
            )
          : const SizedBox.shrink(),
    };
  }
}

class _LatestImagesWidget extends StatefulWidget {
  const _LatestImagesWidget({
    // super.key,
    required this.parent,
    required this.callback,
    required this.selectionActions,
    required this.gallerySearch,
    required this.directoryMetadata,
    required this.directoryTags,
    required this.favoritePosts,
    required this.localTagsService,
  });

  final Directories parent;
  final ReturnFileCallback? callback;

  final Search gallerySearch;
  final SelectionActions selectionActions;

  final DirectoryMetadataService? directoryMetadata;
  final DirectoryTagService? directoryTags;
  final FavoritePostSourceService? favoritePosts;
  final LocalTagsService? localTagsService;

  @override
  State<_LatestImagesWidget> createState() => __LatestImagesWidgetState();
}

class __LatestImagesWidgetState extends State<_LatestImagesWidget> {
  Search get gallerySearch => widget.gallerySearch;

  late final StreamSubscription<void>? _directoryCapsChanged;

  late final filesApi = Files.fake(
    clearRefresh: () {
      final c = <String, DirectoryMetadata>{};

      return gallerySearch.filesByName("", 20).then((l) {
        final ll = _fromDirectoryFileFiltered(l, c);

        if (ll.length < 10) {
          return gallerySearch
              .filesByName("", 20)
              .then((e) => ll + _fromDirectoryFileFiltered(l, c));
        }

        return ll;
      });
    },
    parent: widget.parent,
    directoryMetadata: widget.directoryMetadata,
    directoryTags: widget.directoryTags,
    favoritePosts: widget.favoritePosts,
    localTags: widget.localTagsService,
  );

  late final gridSelection = GridSelection<File>(
    widget.selectionActions.controller,
    const [],
    noAppBar: true,
    source: filesApi.source.backingStorage,
  );

  final focus = FocusNode();

  late final GridFunctionality<File> functionality = GridFunctionality(
    registerNotifiers: (child) => GridExtrasNotifier(
      data: GridExtrasData(
        gridSelection,
        functionality,
        const GridDescription<File>(),
        focus,
      ),
      child: ReturnFileCallbackNotifier(
        callback: widget.callback,
        child: FilesDataNotifier(
          api: filesApi,
          child: child,
        ),
      ),
    ),
    source: filesApi.source,
  );

  final ValueNotifier<bool> scrollNotifier = ValueNotifier(false);
  final controller = ScrollController();

  List<File> _fromDirectoryFileFiltered(
    List<File> l,
    Map<String, DirectoryMetadata> c,
  ) {
    return l
        .where(
          (e) => GalleryFilesPageType.filterAuthBlur(
            c,
            e,
            directoryMetadata: widget.directoryMetadata,
            directoryTag: widget.directoryTags,
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();

    _directoryCapsChanged = widget.directoryMetadata?.watch((_) {
      filesApi.source.clearRefresh();
    });
  }

  @override
  void dispose() {
    _directoryCapsChanged?.cancel();
    focus.dispose();
    filesApi.close();
    scrollNotifier.dispose();
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridExtrasNotifier(
      data: GridExtrasData(
        gridSelection,
        functionality,
        const GridDescription<File>(),
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
              color:
                  theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
            ),
            child: FadingPanel(
              label: "",
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

  final ResourceSource<int, File> source;
  final GridFunctionality<File> functionality;

  static const size = Size(140 / 1.5, 140 + 16);
  static const listPadding = EdgeInsets.symmetric(horizontal: 12);

  @override
  State<_LatestList> createState() => __LatestListState();
}

class __LatestListState extends State<_LatestList> {
  ResourceSource<int, File> get source => widget.source;

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
    return CellProvider<File>(
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
                  onTap: () => cell.onPressed(context, widget.functionality, i),
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: _LatestList.size.width,
                    child: GridCell(
                      data: cell,
                      hideTitle: false,
                      imageAlign: Alignment.topCenter,
                      overrideDescription: const CellStaticData(
                        ignoreSwipeSelectGesture: true,
                        alignStickersTopCenter: true,
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
    this.rootNavigatorPopCond = false,
    required this.child,
  });

  final bool rootNavigatorPopCond;

  final TextEditingController? searchTextController;
  final ChainedFilterResourceSource<dynamic, dynamic>? filter;

  final void Function(bool)? rootNavigatorPop;

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
    final controller = SelectionActions.controllerOf(context);

    return PopScope(
      canPop: widget.rootNavigatorPop != null
          ? widget.rootNavigatorPopCond
          : false ||
              !controller.isExpanded &&
                  (widget.searchTextController == null ||
                      widget.searchTextController!.text.isEmpty) &&
                  (widget.filter == null ||
                      widget.filter!.allowedFilteringModes.isEmpty ||
                      (widget.filter!.allowedFilteringModes
                              .contains(FilteringMode.noFilter) &&
                          widget.filter!.filteringMode ==
                              FilteringMode.noFilter)),
      onPopInvokedWithResult: (didPop, _) {
        if (controller.isExpanded) {
          controller.setCount(0);

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
    required this.callback,
    required this.segmentFnc,
    required super.child,
  });

  final Directories api;
  final GalleryReturnCallback? callback;
  final String Function(Directory cell) segmentFnc;

  static (
    Directories,
    GalleryReturnCallback?,
    String Function(Directory cell),
  ) of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<DirectoriesDataNotifier>();

    return (
      widget!.api,
      widget.callback,
      widget.segmentFnc,
    );
  }

  @override
  bool updateShouldNotify(DirectoriesDataNotifier oldWidget) =>
      api != oldWidget.api ||
      callback != oldWidget.callback ||
      segmentFnc != oldWidget.segmentFnc;
}

class _EmptyWidget extends StatefulWidget {
  const _EmptyWidget({
    // super.key,
    required this.trashCell,
  });

  final TrashCell? trashCell;

  @override
  State<_EmptyWidget> createState() => __EmptyWidgetState();
}

class __EmptyWidgetState extends State<_EmptyWidget> {
  late final StreamSubscription<void>? subscr;

  bool haveTrashCell = true;

  @override
  void initState() {
    super.initState();

    subscr = widget.trashCell?.watch(
      (t) {
        setState(() {
          haveTrashCell = t != null;
        });
      },
      true,
    );
  }

  @override
  void dispose() {
    subscr?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    if (haveTrashCell) {
      return const SizedBox.shrink();
    }

    return EmptyWidgetBackground(
      subtitle: l10n.emptyDevicePictures,
    );
  }
}

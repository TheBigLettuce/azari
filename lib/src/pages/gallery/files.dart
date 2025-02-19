// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:azari/init_main/app_info.dart";
import "package:azari/init_main/restart_widget.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/local_tags_helper.dart";
import "package:azari/src/db/services/obj_impls/file_impl.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files_filters.dart" as filters;
import "package:azari/src/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/platform/pigeon_gallery_data_impl.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/copy_move_preview.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/file_action_chips.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_fab_type.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:azari/src/widgets/grid_frame/layouts/grid_quilted.dart";
import "package:azari/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/menu_wrapper.dart";
import "package:azari/src/widgets/selection_actions.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";

part "files_actions.dart";

class FilesPage extends StatefulWidget {
  const FilesPage({
    super.key,
    required this.api,
    required this.dirName,
    required this.directories,
    required this.navBarEvents,
    required this.scrollingState,
    required this.favoritePosts,
    required this.localTags,
    required this.gridSettings,
    required this.thumbnails,
    required this.tagManager,
    required this.directoryMetadata,
    required this.directoryTags,
    required this.videoSettings,
    required this.downloadManager,
    required this.settingsService,
    required this.miscSettingsService,
    // required this.galleryTrash,
    // required this.cachedThumbs,
    required this.galleryService,
    this.secure,
    this.callback,
    this.presetFilteringValue = "",
    this.filteringMode,
    this.addScaffold = false,
  });

  final bool? secure;
  final bool addScaffold;

  final String dirName;
  final String presetFilteringValue;

  final List<Directory> directories;
  final Directories api;

  final Stream<void>? navBarEvents;
  final ScrollingStateSink? scrollingState;

  final ReturnFileCallback? callback;

  final FilteringMode? filteringMode;

  final FavoritePostSourceService? favoritePosts;
  final LocalTagsService? localTags;
  final ThumbnailService? thumbnails;
  final TagManagerService? tagManager;
  final DirectoryMetadataService? directoryMetadata;
  final VideoSettingsService? videoSettings;
  final MiscSettingsService? miscSettingsService;
  final DownloadManager? downloadManager;
  // final GalleryTrash? galleryTrash;
  // final CachedThumbs? cachedThumbs;
  final GalleryService galleryService;

  final DirectoryTagService? directoryTags;
  final GridSettingsService gridSettings;

  final SettingsService settingsService;

  static Future<void> openProtected({
    required BuildContext context,
    required Directory directory,
    required AppLocalizations l10n,
    required GalleryReturnCallback? callback,
    required Directories api,
    required String Function(Directory) segmentFnc,
    required bool addScaffold,
  }) {
    if (callback?.isDirectory ?? false) {
      Navigator.pop(context);

      (callback! as ReturnDirectoryCallback)(
        (
          bucketId: directory.bucketId,
          path: directory.relativeLoc,
          volumeName: directory.volumeName
        ),
        false,
      );

      return Future.value();
    } else {
      bool requireAuth = false;

      Future<void> onSuccess(bool success) {
        if (!success || !context.mounted) {
          return Future.value();
        }

        StatisticsGalleryService.addViewedDirectories(1);

        return FilesPage.open(
          context,
          api: api,
          directories: [directory],
          secure: requireAuth,
          addScaffold: addScaffold,
          callback: callback?.toFileOrNull,
          dirName: switch (directory.bucketId) {
            "favorites" => l10n.galleryDirectoriesFavorites,
            "trash" => l10n.galleryDirectoryTrash,
            String() => directory.name,
          },
        );
      }

      requireAuth = Services.getOf<DirectoryMetadataService>(context)
              ?.get(segmentFnc(directory))
              ?.requireAuth ??
          false;

      if (AppInfo().canAuthBiometric && requireAuth) {
        return LocalAuthentication()
            .authenticate(
              localizedReason: l10n.openDirectory,
            )
            .then(onSuccess);
      } else {
        return onSuccess(true);
      }
    }
  }

  static Future<void> open(
    BuildContext context, {
    required String dirName,
    required List<Directory> directories,
    required Directories api,
    bool addScaffold = false,
    String presetFilteringValue = "",
    bool? secure,
    ReturnFileCallback? callback,
    FilteringMode? filteringMode,
  }) {
    final db = Services.of(context);
    final (directoryTags, gridSettings, galleryService) = (
      db.get<DirectoryTagService>(),
      db.get<GridSettingsService>(),
      db.get<GalleryService>()
    );
    if (directoryTags == null ||
        gridSettings == null ||
        galleryService == null) {
      // TODO: change
      showSnackbar(context, "Gallery functionality isn't available");

      return Future.value();
    }

    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FilesPage(
            dirName: dirName,
            directories: directories,
            api: api,
            addScaffold: addScaffold,
            presetFilteringValue: presetFilteringValue,
            secure: secure,
            callback: callback,
            filteringMode: filteringMode,
            gridSettings: gridSettings,
            directoryTags: directoryTags,
            // galleryTrash: galleryService.trash,
            // cachedThumbs: galleryService.thumbs,
            galleryService: galleryService,
            navBarEvents: NavigationButtonEvents.maybeOf(context),
            scrollingState: ScrollingStateSinkProvider.maybeOf(context),
            favoritePosts: db.get<FavoritePostSourceService>(),
            localTags: db.get<LocalTagsService>(),
            thumbnails: db.get<ThumbnailService>(),
            tagManager: db.get<TagManagerService>(),
            directoryMetadata: db.get<DirectoryMetadataService>(),
            videoSettings: db.get<VideoSettingsService>(),
            downloadManager: DownloadManager.of(context),
            miscSettingsService: db.get<MiscSettingsService>(),
            settingsService: db.require<SettingsService>(),
          );
        },
      ),
    );
  }

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage>
    with CommonGridData<Post, FilesPage>, MiscSettingsWatcherMixin {
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;
  LocalTagsService? get localTags => widget.localTags;
  WatchableGridSettingsData get gridSettings => widget.gridSettings.files;
  ThumbnailService? get thumbnails => widget.thumbnails;
  TagManagerService? get tagManager => widget.tagManager;
  DirectoryMetadataService? get directoryMetadata => widget.directoryMetadata;
  DirectoryTagService? get directoryTags => widget.directoryTags;
  VideoSettingsService? get videoSettings => widget.videoSettings;
  DownloadManager? get downloadManager => widget.downloadManager;
  GalleryService get galleryService => widget.galleryService;

  @override
  MiscSettingsService? get miscSettingsService => widget.miscSettingsService;

  @override
  SettingsService get settingsService => widget.settingsService;

  final GlobalKey<BarIconState> _favoriteButtonKey = GlobalKey();
  final GlobalKey<BarIconState> _videoButtonKey = GlobalKey();
  final GlobalKey<BarIconState> _duplicateButtonKey = GlobalKey();

  late final Files api;

  AppLifecycleListener? _listener;
  StreamSubscription<void>? _subscription;

  late final ChainedFilterResourceSource<int, File> filter;

  late final searchTextController =
      TextEditingController(text: widget.presetFilteringValue);
  final searchFocus = FocusNode();

  final toShowDelete = DeleteDialogShow();
  late final PigeonGalleryDataImpl impl;

  @override
  void onNewMiscSettings(MiscSettingsData newSettings) {
    if (newSettings.filesExtendedActions !=
        miscSettings!.filesExtendedActions) {
      SelectionActions.of(context).controller.setCount(0);
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.directories.length == 1) {
      final directory = widget.directories.first;

      api = widget.api.files(
        directory,
        switch (directory.bucketId) {
          "favorites" => GalleryFilesPageType.favorites,
          "trash" => GalleryFilesPageType.trash,
          String() => GalleryFilesPageType.normal,
        },
        directoryTags,
        directoryMetadata,
        favoritePosts,
        localTags,
        name: directory.name,
        bucketId: directory.bucketId,
      );
    } else {
      api = widget.api.joinedFiles(
        widget.directories,
        directoryTags,
        directoryMetadata,
        favoritePosts,
        localTags,
      );
    }

    filter = ChainedFilterResourceSource(
      api.source,
      ListStorage(),
      onCompletelyEmpty: () {
        Navigator.pop(context);
      },
      prefilter: () {
        if (filter.filteringMode == FilteringMode.favorite) {
          _favoriteButtonKey.currentState?.toggle(true);
          _duplicateButtonKey.currentState?.toggle(false);
          _videoButtonKey.currentState?.toggle(false);
        } else if (filter.filteringMode == FilteringMode.duplicate) {
          _duplicateButtonKey.currentState?.toggle(true);
          _favoriteButtonKey.currentState?.toggle(false);
          _videoButtonKey.currentState?.toggle(false);
        } else if (filter.filteringMode == FilteringMode.video) {
          _videoButtonKey.currentState?.toggle(true);
          _favoriteButtonKey.currentState?.toggle(false);
          _duplicateButtonKey.currentState?.toggle(false);
        } else {
          _duplicateButtonKey.currentState?.toggle(false);
          _favoriteButtonKey.currentState?.toggle(false);
          _videoButtonKey.currentState?.toggle(false);
          beforeButtons = null;
        }

        if (filter.filteringMode == FilteringMode.same) {
          StatisticsGalleryService.addSameFiltered(1);
        }
      },
      filter: (cells, filteringMode, sortingMode, end, [data]) {
        return switch (filteringMode) {
          FilteringMode.favorite => favoritePosts != null
              ? filters.favorite(
                  cells,
                  favoritePosts!,
                  searchTextController.text,
                )
              : (cells, data),
          FilteringMode.untagged => filters.untagged(cells),
          FilteringMode.tag => filters.tag(cells, searchTextController.text),
          FilteringMode.tagReversed =>
            filters.tagReversed(cells, searchTextController.text),
          FilteringMode.video => filters.video(cells),
          FilteringMode.gif => filters.gif(cells),
          FilteringMode.duplicate => filters.duplicate(cells),
          FilteringMode.original => filters.original(cells),
          FilteringMode.same => thumbnails != null
              ? filters.same(
                  cells,
                  data,
                  onSkipped: () {
                    if (!context.mounted || thumbnails == null) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(context.l10n().resultsIncomplete),
                          duration: const Duration(seconds: 20),
                          action: SnackBarAction(
                            label: context.l10n().loadMoreLabel,
                            onPressed: () {
                              filters.loadNextThumbnails(
                                api.source,
                                () {
                                  try {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(context.l10n().loaded),
                                      ),
                                    );
                                    api.source.clearRefreshSilent();
                                  } catch (_) {}
                                },
                                thumbnails!,
                                galleryService.thumbs,
                              );
                            },
                          ),
                        ),
                      );
                  },
                  end: end,
                  source: api.source,
                  thumbnailService: thumbnails!,
                )
              : (cells, data),
          FilteringMode() => (
              searchTextController.text.isEmpty
                  ? cells
                  : cells
                      .where((e) => e.name.contains(searchTextController.text)),
              data
            ),
        };
      },
      allowedFilteringModes: {
        FilteringMode.noFilter,
        if (api.type != GalleryFilesPageType.favorites && favoritePosts != null)
          FilteringMode.favorite,
        FilteringMode.original,
        FilteringMode.duplicate,
        if (thumbnails != null) FilteringMode.same,
        FilteringMode.tag,
        FilteringMode.tagReversed,
        FilteringMode.untagged,
        FilteringMode.gif,
        FilteringMode.video,
      },
      allowedSortingModes: const {
        SortingMode.none,
        SortingMode.size,
      },
      initialFilteringMode: widget.filteringMode ?? FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    impl = PigeonGalleryDataImpl(
      source: filter,
      tags: localTags != null && tagManager != null
          ? (c) => FileImpl.imageTags(c, localTags!, tagManager!)
          : null,
      watchTags: localTags != null && tagManager != null
          ? (c, f) => FileImpl.watchTags(c, f, localTags!, tagManager!.pinned)
          : null,
      wrapNotifiers: (child) => ReturnFileCallbackNotifier(
        callback: widget.callback,
        child: FilesDataNotifier(
          api: api,
          child: DeleteDialogShowNotifier(
            toShow: toShowDelete,
            child: OnBooruTagPressed(
              onPressed: _onBooruTagPressed,
              child: filter.inject(child),
            ),
          ),
        ),
      ),
      videoSettings: videoSettings,
    );

    watchSettings();

    final secure = widget.secure ??
        (widget.directories.length == 1
            ? directoryMetadata
                    ?.get(_segmentCell(widget.directories.first))
                    ?.requireAuth ??
                false
            : false);

    if (secure) {
      _listener = AppLifecycleListener(
        onHide: () {
          _subscription?.cancel();
          _subscription = Stream<void>.periodic(const Duration(seconds: 10))
              .listen((event) {
            filter.backingStorage.clear();

            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();

            _subscription?.cancel();

            return;
          });
        },
        onShow: () {
          _subscription?.cancel();
          _subscription = null;
        },
      );

      PlatformApi().window.setProtected(true);
    }

    api.source.clearRefreshSilent();

    FlutterGalleryData.setUp(impl);
    GalleryVideoEvents.setUp(impl);
  }

  @override
  void dispose() {
    FlutterGalleryData.setUp(null);
    GalleryVideoEvents.setUp(null);

    impl.dispose();

    _subscription?.cancel();
    _listener?.dispose();

    searchFocus.dispose();
    searchTextController.dispose();
    filter.destroy();

    api.close();

    PlatformApi().window.setProtected(false);

    super.dispose();
  }

  String _segmentCell(Directory cell) => DirectoriesPage.segmentCell(
        cell.name,
        cell.bucketId,
        directoryTags,
      );

  void _onBooruTagPressed(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? overrideSafeMode,
  ) {
    if (overrideSafeMode != null) {
      PauseVideoNotifier.maybePauseOf(context, true);

      BooruRestoredPage.open(
        context,
        booru: booru,
        tags: tag,
        rootNavigator: true,
        saveSelectedPage: (e) {},
        overrideSafeMode: overrideSafeMode,
      ).then((value) {
        if (context.mounted) {
          PauseVideoNotifier.maybePauseOf(context, false);
        }
      });

      return;
    }

    searchTextController.text = tag;
    filter.filteringMode = FilteringMode.tag;
    if (filter.backingStorage.isNotEmpty) {
      ExitOnPressRoute.maybeExitOf(context);
      // Navigator.pop(context);
    }
  }

  FilteringMode? beforeButtons;

  PathVolume? makeThenMoveTo() {
// ((widget.directory == null
//                                               ? api.directories.length == 1
//                                               : true)
//                                           ? () {
//                                               final dir = widget.directory ??
//                                                   api.directories.first;

//                                               return PathVolume(
//                                                 dir.relativeLoc,
//                                                 dir.volumeName,
//                                                 widget.dirName,
//                                               );
//                                             }
//                                           : null)
//                                       ?.call()

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();

    return FlutterGalleryDataNotifier(
      galleryDataImpl: impl,
      child: GridConfiguration(
        watch: gridSettings.watch,
        child: WrapGridPage(
          addScaffoldAndBar: widget.addScaffold || widget.callback != null,
          child: GridPopScope(
            searchTextController: searchTextController,
            filter: filter,
            child: Builder(
              builder: (context) => GridFrame<File>(
                key: ValueKey(miscSettings?.filesExtendedActions),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          padding: const EdgeInsets.only(left: 18, right: 12),
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Builder(
                                builder: (context) => IconButton(
                                  padding: EdgeInsets.zero,
                                  // labelPadding: EdgeInsets.zero,
                                  // label: SizedBox(
                                  // height: 38,
                                  // ),
                                  onPressed: () {
                                    final gridExtras =
                                        GridExtrasNotifier.of<File>(context);
                                    if (gridExtras.selection == null) {
                                      return;
                                    }

                                    if (gridExtras.selection!.count ==
                                        gridExtras.functionality.source.count) {
                                      gridExtras.selection!.reset(true);
                                    } else {
                                      gridExtras.selection!.selectAll();
                                    }
                                  },
                                  icon: const Icon(Icons.select_all_rounded),
                                ),
                              ),
                            ),
                            StreamBuilder(
                              stream: filter.filterEvents,
                              builder: (context, value) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    showCheckmark: false,
                                    avatar: Icon(FilteringMode.duplicate.icon),
                                    selected: filter.filteringMode ==
                                        FilteringMode.duplicate,
                                    label:
                                        Text(l10n.enumFilteringModeDuplicate),
                                    onSelected: (value) {
                                      if (filter.filteringMode ==
                                          FilteringMode.duplicate) {
                                        filter.filteringMode = beforeButtons ==
                                                FilteringMode.duplicate
                                            ? FilteringMode.noFilter
                                            : (beforeButtons ??
                                                FilteringMode.noFilter);
                                        return;
                                      } else {
                                        beforeButtons = filter.filteringMode;
                                        filter.filteringMode =
                                            FilteringMode.duplicate;
                                        return;
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            StreamBuilder(
                              stream: filter.filterEvents,
                              builder: (context, value) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    showCheckmark: false,
                                    avatar: Icon(FilteringMode.favorite.icon),
                                    selected: filter.filteringMode ==
                                        FilteringMode.favorite,
                                    label: Text(l10n.favoritesLabel),
                                    onSelected: (value) {
                                      if (filter.filteringMode ==
                                          FilteringMode.favorite) {
                                        filter.filteringMode = beforeButtons ==
                                                FilteringMode.favorite
                                            ? FilteringMode.noFilter
                                            : beforeButtons ??
                                                FilteringMode.noFilter;
                                        return;
                                      } else {
                                        beforeButtons = filter.filteringMode;
                                        filter.filteringMode =
                                            FilteringMode.favorite;
                                        return;
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            StreamBuilder(
                              stream: filter.filterEvents,
                              builder: (context, value) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    showCheckmark: false,
                                    avatar: Icon(FilteringMode.video.icon),
                                    selected: filter.filteringMode ==
                                        FilteringMode.video,
                                    label: Text(l10n.videosLabel),
                                    onSelected: (value) {
                                      if (filter.filteringMode ==
                                          FilteringMode.video) {
                                        filter.filteringMode =
                                            beforeButtons == FilteringMode.video
                                                ? FilteringMode.noFilter
                                                : beforeButtons ??
                                                    FilteringMode.noFilter;
                                        return;
                                      } else {
                                        beforeButtons = filter.filteringMode;
                                        filter.filteringMode =
                                            FilteringMode.video;
                                        return;
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  CurrentGridSettingsLayout<File>(
                    source: filter.backingStorage,
                    progress: filter.progress,
                    gridSeed: gridSeed,
                  ),
                ],
                functionality: GridFunctionality(
                  selectionActions: SelectionActions.of(context),
                  scrollingState: widget.scrollingState,
                  scrollUpOn: widget.navBarEvents == null
                      ? const []
                      : [(widget.navBarEvents!, null)],
                  fab: widget.callback == null
                      ? const NoGridFab()
                      : const DefaultGridFab(),
                  onEmptySource: EmptyWidgetBackground(
                    subtitle: l10n.emptyNoMedia,
                  ),
                  settingsButton: GridSettingsButton.fromWatchable(
                    gridSettings,
                    header: miscSettingsService != null
                        ? _ShowAdditionalButtons(
                            miscSettingsService: miscSettingsService!,
                          )
                        : null,
                    localizeHideNames: (context) =>
                        l10n.hideNames(l10n.hideNamesFiles),
                  ),
                  registerNotifiers: (child) {
                    return ReturnFileCallbackNotifier(
                      callback: widget.callback,
                      child: FilesDataNotifier(
                        api: api,
                        child: DeleteDialogShowNotifier(
                          toShow: toShowDelete,
                          child: OnBooruTagPressed(
                            onPressed: _onBooruTagPressed,
                            child: filter.inject(child),
                          ),
                        ),
                      ),
                    );
                  },
                  backButton: CallbackGridBackButton(
                    onPressed: () {
                      if (filter.filteringMode != FilteringMode.noFilter) {
                        filter.filteringMode = FilteringMode.noFilter;
                        return;
                      }
                      Navigator.pop(context);
                    },
                  ),
                  source: filter,
                  search: BarSearchWidget.fromFilter(
                    filter,
                    hintText: widget.dirName,
                    textEditingController: searchTextController,
                    focus: searchFocus,
                    complete: localTags?.complete,
                    trailingItems: [
                      if (widget.callback == null && api.type.isTrash())
                        IconButton(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).push(
                              DialogRoute<void>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(l10n.emptyTrashTitle),
                                    content: Text(
                                      l10n.thisIsPermanent,
                                      style: TextStyle(
                                        color: Colors.red.harmonizeWith(
                                          theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          galleryService.trash.empty();
                                          Navigator.pop(context);
                                        },
                                        child: Text(l10n.yes),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(l10n.no),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_sweep_outlined),
                        ),
                      if (widget.callback != null)
                        Builder(
                          builder: (context) => IconButton(
                            onPressed: () {
                              if (filter.progress.inRefreshing) {
                                return;
                              }

                              final upTo = filter.backingStorage.count;

                              try {
                                final n = math.Random.secure().nextInt(upTo);

                                final gridState = gridKey.currentState;
                                if (gridState != null) {
                                  final cell = gridState.source.forIdxUnsafe(n);
                                  cell.onPressed(
                                    context,
                                    gridState.widget.functionality,
                                    n,
                                  );
                                }
                              } catch (e, trace) {
                                Logger.root
                                    .warning("getting random number", e, trace);

                                return;
                              }

                              if (widget.callback!.returnBack) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.casino_outlined),
                          ),
                        ),
                    ],
                  ),
                ),
                description: GridDescription(
                  footer: widget.callback?.preview,
                  overrideEmptyWidgetNotice:
                      api.type.isFavorites() ? l10n.someFilesShownNotice : null,
                  actions: widget.callback != null
                      ? const <GridAction<File>>[]
                      : api.type.isTrash()
                          ? <GridAction<File>>[
                              _restoreFromTrashAction(galleryService.trash),
                            ]
                          : <GridAction<File>>[
                              if (api.type.isFavorites() &&
                                  miscSettingsService != null)
                                _setFavoritesThumbnailAction(
                                  miscSettingsService!,
                                ),
                              if (miscSettings?.filesExtendedActions ??
                                  false) ...[
                                if (downloadManager != null &&
                                    localTags != null)
                                  GridAction(
                                    Icons.download_rounded,
                                    (selected) {
                                      redownloadFiles(
                                        context,
                                        selected,
                                        downloadManager: downloadManager!,
                                        localTags: localTags!,
                                        settingsService: settingsService,
                                        galleryService: galleryService,
                                      );
                                    },
                                    true,
                                  ),
                                if (localTags != null)
                                  _saveTagsAction(
                                    context,
                                    localTags: localTags!,
                                    galleryService: galleryService,
                                  ),
                                if (localTags != null)
                                  _addTagAction(
                                    context,
                                    () => api.source.clearRefreshSilent(),
                                    localTags!,
                                  ),
                              ],
                              _deleteAction(
                                context,
                                toShowDelete,
                                galleryService.trash,
                              ),
                              if (tagManager != null && localTags != null)
                                _copyAction(
                                  context,
                                  api.bucketId,
                                  api.parent,
                                  toShowDelete,
                                  galleryService: galleryService,
                                  tagManager: tagManager!,
                                  localTags: localTags!,
                                ),
                              if (tagManager != null && localTags != null)
                                _moveAction(
                                  context,
                                  api.bucketId,
                                  api.parent,
                                  toShowDelete,
                                  galleryService: galleryService,
                                  tagManager: tagManager!,
                                  localTags: localTags!,
                                ),
                            ],
                  pageName: widget.dirName,
                  gridSeed: gridSeed,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowAdditionalButtons extends StatefulWidget {
  const _ShowAdditionalButtons({
    // super.key,
    required this.miscSettingsService,
  });

  final MiscSettingsService miscSettingsService;

  @override
  State<_ShowAdditionalButtons> createState() => __ShowAdditionalButtonsState();
}

class __ShowAdditionalButtonsState extends State<_ShowAdditionalButtons>
    with MiscSettingsWatcherMixin {
  @override
  MiscSettingsService get miscSettingsService => widget.miscSettingsService;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SwitchListTile(
      value: miscSettings!.filesExtendedActions,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      onChanged: (value) => miscSettingsService.current
          .copy(filesExtendedActions: value)
          .maybeSave(),
      title: Text(l10n.extendedFilesGridActions),
    );
  }
}

class FlutterGalleryDataNotifier extends InheritedWidget {
  const FlutterGalleryDataNotifier({
    super.key,
    required this.galleryDataImpl,
    required super.child,
  });

  final PigeonGalleryDataImpl galleryDataImpl;

  static PigeonGalleryDataImpl of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<FlutterGalleryDataNotifier>();

    return widget!.galleryDataImpl;
  }

  @override
  bool updateShouldNotify(FlutterGalleryDataNotifier oldWidget) =>
      galleryDataImpl != oldWidget.galleryDataImpl;
}

class _TagsNotifier extends StatefulWidget {
  const _TagsNotifier({
    // super.key,
    required this.tagManager,
    required this.tagSource,
    required this.child,
  });

  final FilesSourceTags tagSource;
  final TagManagerService tagManager;

  final Widget child;

  @override
  State<_TagsNotifier> createState() => __TagsNotifierState();
}

class __TagsNotifierState extends State<_TagsNotifier> {
  late final StreamSubscription<List<String>> subscription;
  late final StreamSubscription<void> subscr;

  final _tags = ImageViewTags();

  @override
  void initState() {
    super.initState();

    _tags.update(
      widget.tagSource.current
          .map(
            (e) => ImageTag(
              e,
              favorite: widget.tagManager.pinned.exists(e),
              excluded: widget.tagManager.excluded.exists(e),
            ),
          )
          .toList(),
      null,
    );

    subscription = widget.tagSource.watch((list) {
      _refresh();
    });

    subscr = widget.tagManager.pinned.watch((_) {
      _refresh();
    });
  }

  void _refresh() {
    setState(() {
      _tags.update(
        widget.tagSource.current
            .map(
              (e) => ImageTag(
                e,
                favorite: widget.tagManager.pinned.exists(e),
                excluded: widget.tagManager.excluded.exists(e),
              ),
            )
            .toList(),
        null,
      );
    });
  }

  @override
  void dispose() {
    _tags.dispose();
    subscription.cancel();
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImageTagsNotifier(
      tags: _tags,
      child: widget.child,
    );
  }
}

class TagsRibbon extends StatefulWidget {
  const TagsRibbon({
    super.key,
    required this.selectTag,
    required this.tagManager,
    this.onLongPress,
    this.items,
    this.showPin = true,
    this.emptyWidget = const SliverPadding(padding: EdgeInsets.zero),
    this.sliver = true,
    required this.tagNotifier,
  });

  final bool showPin;
  final bool sliver;

  final TagManagerService? tagManager;
  final ImageViewTags tagNotifier;

  final Widget emptyWidget;

  final void Function(String tag, ScrollController controller)? onLongPress;
  final void Function(String tag, ScrollController controller)? selectTag;
  final List<PopupMenuItem<void>> Function(
    String tag,
    ScrollController controller,
  )? items;

  @override
  State<TagsRibbon> createState() => _TagsRibbonState();
}

class _TagsRibbonState extends State<TagsRibbon> {
  TagManagerService? get tagManager => widget.tagManager;

  late final StreamSubscription<void>? pinnedSubscription;
  late final StreamSubscription<void> _events;

  final scrollController = ScrollController();

  late List<ImageTag> _list;
  late List<ImageTag>? _pinnedList = !widget.showPin || tagManager == null
      ? null
      : tagManager!.pinned
          .get(-1)
          .map(
            (e) => ImageTag(
              e.tag,
              favorite: true,
              excluded: false,
            ),
          )
          .toList();

  bool showOnlyPinned = false;

  @override
  void initState() {
    super.initState();

    _events = widget.tagNotifier.stream.listen((_) {
      _list = _sortPinned(widget.tagNotifier.list);

      setState(() {});
    });

    pinnedSubscription = !widget.showPin || tagManager == null
        ? null
        : tagManager!.pinned.watch((_) {
            setState(() {
              _pinnedList = tagManager!.pinned
                  .get(-1)
                  .map(
                    (e) => ImageTag(
                      e.tag,
                      favorite: true,
                      excluded: false,
                    ),
                  )
                  .toList();
            });
          });

    _list = _sortPinned(widget.tagNotifier.list);
  }

  List<ImageTag> _sortPinned(List<ImageTag> tag) {
    final pinned = <ImageTag>[];
    final notPinned = <ImageTag>[];

    for (final e in tag) {
      if (e.favorite) {
        pinned.add(e);
      } else {
        notPinned.add(e);
      }
    }

    return pinned.followedBy(notPinned).toList();
  }

  @override
  void dispose() {
    _events.cancel();
    pinnedSubscription?.cancel();
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();
    final gestureRight = MediaQuery.systemGestureInsetsOf(context).right;

    final fromList = showOnlyPinned || _list.isEmpty && _pinnedList != null
        ? _pinnedList!
        : _list;

    final child = ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (fromList.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.noBooruTags,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12) +
                    (widget.showPin
                        ? EdgeInsets.only(
                            right: 40 + gestureRight * 0.5,
                          )
                        : EdgeInsets.zero),
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: fromList.length,
                itemBuilder: (context, i) {
                  final elem = fromList[i];

                  final child = GestureDetector(
                    onDoubleTap: tagManager != null
                        ? () {
                            if (tagManager!.pinned.exists(elem.tag)) {
                              tagManager!.pinned.delete(elem.tag);
                            } else {
                              tagManager!.pinned.add(elem.tag);
                            }

                            scrollController.animateTo(
                              0,
                              duration: Durations.medium1,
                              curve: Easing.standard,
                            );
                          }
                        : null,
                    child: TextButton(
                      onLongPress: widget.onLongPress == null
                          ? null
                          : () {
                              widget.onLongPress!(
                                elem.tag,
                                scrollController,
                              );
                            },
                      onPressed: widget.selectTag == null
                          ? null
                          : () => widget.selectTag!(
                                elem.tag,
                                scrollController,
                              ),
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        elem.tag,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: elem.excluded
                              ? theme.disabledColor
                              : elem.favorite
                                  ? theme.colorScheme.primary
                                  : null,
                        ),
                      ),
                    ),
                  );

                  return Padding(
                    key: ValueKey(elem.tag),
                    padding: i != fromList.length - 1
                        ? const EdgeInsets.only(right: 6)
                        : EdgeInsets.zero,
                    child: widget.items == null
                        ? child
                        : MenuWrapper(
                            title: elem.tag,
                            items: widget.items!(
                              elem.tag,
                              scrollController,
                            ),
                            child: child,
                          ),
                  );
                },
              ),
            ),
          if (widget.showPin)
            Align(
              alignment: Alignment.centerRight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withValues(alpha: 0.8),
                      theme.colorScheme.surface.withValues(alpha: 0.65),
                      theme.colorScheme.surface.withValues(alpha: 0.5),
                      theme.colorScheme.surface.withValues(alpha: 0.35),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(right: gestureRight * 0.5),
                  child: IconButton(
                    onPressed: _list.isEmpty
                        ? null
                        : () {
                            setState(() {
                              showOnlyPinned = !showOnlyPinned;
                            });
                          },
                    icon: const Icon(Icons.push_pin_rounded),
                    isSelected: showOnlyPinned,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return _list.isEmpty && (_pinnedList == null || _pinnedList!.isEmpty)
        ? widget.emptyWidget
        : !widget.sliver
            ? Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: child,
              )
            : SliverPadding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                sliver: SliverToBoxAdapter(
                  child: child,
                ),
              );
  }
}

class BarIcon extends StatefulWidget {
  const BarIcon({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final bool? Function() onPressed;

  @override
  State<BarIcon> createState() => BarIconState();
}

class BarIconState extends State<BarIcon> {
  bool _toggled = false;

  void toggle(bool v) => setState(() {
        _toggled = v;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () {
          widget.onPressed();
        },
        child: SizedBox(
          width: 36,
          height: 36,
          child: TweenAnimationBuilder(
            tween: DecorationTween(
              end: _toggled
                  ? ShapeDecoration(
                      color: theme.colorScheme.primary,
                      shape: const CircleBorder(),
                    )
                  : ShapeDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
            ),
            duration: Durations.medium3,
            curve: Easing.standard,
            builder: (context, value, child) => DecoratedBox(
              decoration: value,
              child: child ?? const SizedBox.shrink(),
            ),
            child: Center(
              child: TweenAnimationBuilder(
                tween: ColorTween(
                  end: _toggled
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                      : theme.colorScheme.primary.withValues(alpha: 0.9),
                ),
                duration: Durations.medium3,
                curve: Easing.standard,
                builder: (context, value, child) => Icon(
                  widget.icon,
                  color: value,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IconBarGridHeader extends StatelessWidget {
  const IconBarGridHeader({
    super.key,
    required this.icons,
    this.countWatcher,
  });

  final List<BarIcon> icons;
  final WatchFire<int>? countWatcher;

  @override
  Widget build(BuildContext context) {
    final gestureInsets = MediaQuery.systemGestureInsetsOf(context);

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: 8 + gestureInsets.right * 0.5,
        vertical: 8,
      ),
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          child: Row(
            mainAxisAlignment: countWatcher == null
                ? MainAxisAlignment.end
                : MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.select_all_rounded),
                    onPressed: () {
                      final gridExtras = GridExtrasNotifier.of<File>(context);
                      if (gridExtras.selection == null) {
                        return;
                      }

                      if (gridExtras.selection!.count ==
                          gridExtras.functionality.source.count) {
                        gridExtras.selection!.reset(true);
                      } else {
                        gridExtras.selection!.selectAll();
                      }
                    },
                  ),
                  if (countWatcher != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: _CountWatcher(countWatcher: countWatcher!),
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: icons,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountWatcher extends StatefulWidget {
  const _CountWatcher({
    // super.key,
    required this.countWatcher,
  });

  final WatchFire<int> countWatcher;

  @override
  State<_CountWatcher> createState() => __CountWatcherState();
}

class __CountWatcherState extends State<_CountWatcher> {
  late final StreamSubscription<int> subsc;

  int count = 0;

  @override
  void initState() {
    super.initState();

    subsc = widget.countWatcher(
      (i) {
        setState(() {
          count = i;
        });
      },
      true,
    );
  }

  @override
  void dispose() {
    subsc.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      count.toString(),
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

class CurrentGridSettingsLayout<T extends CellBase> extends StatelessWidget {
  const CurrentGridSettingsLayout({
    super.key,
    required this.source,
    this.hideThumbnails = false,
    required this.gridSeed,
    this.buildEmpty,
    required this.progress,
    this.unselectOnUpdate = true,
  });

  final bool hideThumbnails;
  final bool unselectOnUpdate;

  final int gridSeed;

  final SourceStorage<int, T> source;
  final Widget Function(Object?)? buildEmpty;
  final RefreshingProgress progress;

  @override
  Widget build(BuildContext context) {
    final config = GridConfiguration.of(context);

    return switch (config.layoutType) {
      GridLayoutType.grid => GridLayout<T>(
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          unselectOnUpdate: unselectOnUpdate,
        ),
      GridLayoutType.list => ListLayout<T>(
          hideThumbnails: hideThumbnails,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          unselectOnUpdate: unselectOnUpdate,
        ),
      GridLayoutType.gridQuilted => GridQuiltedLayout<T>(
          randomNumber: gridSeed,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          unselectOnUpdate: unselectOnUpdate,
        ),
      // GridLayoutType.gridMasonry => GridMasonryLayout(
      //     randomNumber: gridSeed,
      //     source: source,
      //     progress: progress,
      //     buildEmpty: buildEmpty,
      //     unselectOnUpdate: unselectOnUpdate,
      //   ),
    };
  }
}

class FilesDataNotifier extends InheritedWidget {
  const FilesDataNotifier({
    super.key,
    required this.api,
    required super.child,
  });

  final Files api;

  static Files? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<FilesDataNotifier>();

    return widget?.api;
  }

  @override
  bool updateShouldNotify(FilesDataNotifier oldWidget) => api != oldWidget.api;
}

class ReturnFileCallbackNotifier extends InheritedWidget {
  const ReturnFileCallbackNotifier({
    super.key,
    required this.callback,
    required super.child,
  });

  final ReturnFileCallback? callback;

  static ReturnFileCallback? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<ReturnFileCallbackNotifier>();

    return widget?.callback;
  }

  @override
  bool updateShouldNotify(ReturnFileCallbackNotifier oldWidget) =>
      callback != oldWidget.callback;
}

class GridFooter<T> extends StatefulWidget {
  const GridFooter({
    super.key,
    required this.storage,
    this.name,
    this.statistics,
  });

  final String? name;

  final ReadOnlyStorage<dynamic, dynamic> storage;

  final (List<Widget> Function(T), WatchFire<T>)? statistics;

  @override
  State<GridFooter<T>> createState() => _GridFooterState();
}

class _GridFooterState<T> extends State<GridFooter<T>> {
  late final StreamSubscription<int> watcher;

  @override
  void initState() {
    super.initState();

    watcher = widget.storage.watch((_) => setState(() {}));
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();

    if (widget.storage.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    if (widget.name != null)
                      TextSpan(
                        text: "${widget.name}\n",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    TextSpan(
                      text:
                          "${widget.storage.count} ${widget.storage.count == 1 ? l10n.elementSingular : l10n.elementPlural}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.statistics != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "~",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              if (widget.statistics != null)
                _StatisticsPanel<T>(statistics: widget.statistics!),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsPanel<T> extends StatefulWidget {
  const _StatisticsPanel({
    super.key,
    required this.statistics,
  });

  final (List<Widget> Function(T), WatchFire<T>) statistics;

  @override
  State<_StatisticsPanel<T>> createState() => __StatisticsPanelState();
}

class __StatisticsPanelState<T> extends State<_StatisticsPanel<T>> {
  late final StreamSubscription<T> subscr;

  T? value;

  @override
  @override
  void initState() {
    super.initState();

    subscr = widget.statistics.$2(
      (e) {
        setState(() {
          value = e;
        });
      },
      true,
    );
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    final values = widget.statistics.$1(value as T);

    return SizedBox(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ...values.take(values.length - 1).fold<List<Widget>>([], (v, w) {
            v.add(w);
            v.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "・",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                ),
              ),
            );

            return v;
          }),
          values.last,
        ],
      ),
    );
  }
}

class StatisticsCard extends StatelessWidget {
  const StatisticsCard({
    super.key,
    required this.subtitle,
    required this.title,
  });

  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$subtitle\n",
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
          TextSpan(
            text: title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

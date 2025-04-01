// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/generated/platform/platform_api.g.dart" as platform;
import "package:azari/src/logic/directories_mixin.dart";
import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/io/pigeon_gallery_data_impl.dart";
import "package:azari/src/services/impl/obj/file_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/booru/booru_restored_page.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files_filters.dart"
    as filters;
import "package:azari/src/ui/material/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/copy_move_preview.dart";
import "package:azari/src/ui/material/widgets/file_action_chips.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/menu_wrapper.dart";
import "package:azari/src/ui/material/widgets/scaffold_selection_bar.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_fab_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/grid_layout.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/list_layout.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/quilted_grid.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
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
    this.secure,
    this.callback,
    this.presetFilteringValue = "",
    this.filteringMode,
    this.addScaffold = false,
    required this.selectionController,
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

  final SelectionController selectionController;

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
      Navigator.maybePop(context);

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

      requireAuth = DirectoryMetadataService.safe()
              ?.cache
              .get(segmentFnc(directory))
              ?.requireAuth ??
          false;

      if (const AppApi().canAuthBiometric && requireAuth) {
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

  static bool hasServicesRequired() =>
      DirectoryTagService.available &&
      GridSettingsService.available &&
      GalleryService.available;

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
    if (!hasServicesRequired()) {
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
            selectionController: SelectionActions.controllerOf(context),
            navBarEvents: NavigationButtonEvents.maybeOf(context),
            scrollingState: ScrollingStateSinkProvider.maybeOf(context),
          );
        },
      ),
    );
  }

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> with SettingsWatcherMixin {
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
  late final PlatformImageViewStateImpl impl;

  late final SourceShellElementState<File> status;

  // @override
  // void onNewMiscSettings(MiscSettingsData newSettings) {
  //   if (newSettings.filesExtendedActions !=
  //       miscSettings!.filesExtendedActions) {
  //     SelectionActions.of(context).controller.setCount(0);
  //   }
  // }

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
        name: directory.name,
        bucketId: directory.bucketId,
      );
    } else {
      api = widget.api.joinedFiles(widget.directories);
    }

    filter = ChainedFilterResourceSource(
      api.source,
      ListStorage(),
      onCompletelyEmpty: () {
        Navigator.maybePop(context);
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
          FilteringMode.favorite => FavoritePostSourceService.available
              ? filters.favorite(
                  cells,
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
          FilteringMode.same => ThumbnailService.available
              ? filters.same(
                  cells,
                  data,
                  onSkipped: () {
                    if (!context.mounted || !ThumbnailService.available) {
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
                              );
                            },
                          ),
                        ),
                      );
                  },
                  end: end,
                  source: api.source,
                )
              : (cells, data),
          FilteringMode.onlyFullStars => filters.stars(cells, false),
          FilteringMode.onlyHalfStars => filters.stars(cells, true),
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
        if (api.type != GalleryFilesPageType.favorites &&
            FavoritePostSourceService.available)
          FilteringMode.favorite,
        FilteringMode.original,
        FilteringMode.duplicate,
        if (ThumbnailService.available) FilteringMode.same,
        FilteringMode.tag,
        FilteringMode.tagReversed,
        FilteringMode.untagged,
        FilteringMode.gif,
        FilteringMode.video,
        FilteringMode.onlyFullStars,
        FilteringMode.onlyHalfStars,
      },
      allowedSortingModes: const {
        SortingMode.none,
        SortingMode.size,
        SortingMode.stars,
      },
      initialFilteringMode: widget.filteringMode ?? FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    impl = PlatformImageViewStateImpl(
      source: filter,
      tags: LocalTagsService.available && TagManagerService.available
          ? FileImpl.imageTags
          : null,
      watchTags: LocalTagsService.available && TagManagerService.available
          ? FileImpl.watchTags
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
    );

    status = SourceShellElementState(
      source: filter,
      selectionController: widget.selectionController,
      onEmpty: SourceOnEmptyInterface(
        filter,
        (context) => context.l10n().emptyNoMedia,
      ),
      actions: widget.callback != null
          ? const <SelectionBarAction>[]
          : api.type.isTrash()
              ? <SelectionBarAction>[
                  _restoreFromTrashAction(const GalleryService().trash),
                ]
              : <SelectionBarAction>[
                  if (settings.filesExtendedActions) ...[
                    if (DownloadManager.available && LocalTagsService.available)
                      SelectionBarAction(
                        Icons.download_rounded,
                        (selected) {
                          const TasksService().add<DownloadManager>(
                            () => redownloadFiles(
                              context.l10n(),
                              selected.cast(),
                            ),
                          );
                        },
                        true,
                        taskTag: DownloadManager,
                      ),
                    if (LocalTagsService.available)
                      _saveTagsAction(context.l10n()),
                    if (LocalTagsService.available)
                      _addTagAction(
                        context,
                        () => api.source.clearRefreshSilent(),
                      ),
                  ],
                  _deleteAction(
                    context,
                    toShowDelete,
                    const GalleryService().trash,
                  ),
                  if (TagManagerService.available && LocalTagsService.available)
                    _copyAction(
                      context,
                      api.bucketId,
                      api.parent,
                      toShowDelete,
                    ),
                  if (TagManagerService.available && LocalTagsService.available)
                    _moveAction(
                      context,
                      api.bucketId,
                      api.parent,
                      toShowDelete,
                    ),
                ],
    );

    final secure = widget.secure ??
        (widget.directories.length == 1
            ? DirectoryMetadataService.safe()
                    ?.cache
                    .get(_segmentCell(widget.directories.first))
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
            Navigator.of(context).maybePop();

            _subscription?.cancel();

            return;
          });
        },
        onShow: () {
          _subscription?.cancel();
          _subscription = null;
        },
      );

      const WindowApi().setProtected(true);
    }

    api.source.clearRefreshSilent();

    platform.FlutterGalleryData.setUp(impl);
    platform.GalleryVideoEvents.setUp(impl);
  }

  @override
  void dispose() {
    platform.FlutterGalleryData.setUp(null);
    platform.GalleryVideoEvents.setUp(null);

    status.destroy();
    impl.dispose();

    _subscription?.cancel();
    _listener?.dispose();

    searchFocus.dispose();
    searchTextController.dispose();
    filter.destroy();

    api.close();

    const WindowApi().setProtected(false);

    super.dispose();
  }

  String _segmentCell(Directory cell) =>
      defaultSegmentCell(cell.name, cell.bucketId);

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
    final gridSettings = GridSettingsData<FilesData>();

    return FlutterGalleryDataNotifier(
      galleryDataImpl: impl,
      child: ScaffoldSelectionBar(
        addScaffoldAndBar: widget.addScaffold || widget.callback != null,
        child: GridPopScope(
          searchTextController: searchTextController,
          filter: filter,
          child: ShellScope(
            footer: widget.callback?.preview,
            stackInjector: status,
            fab: widget.callback == null
                ? const NoShellFab()
                : const DefaultShellFab(),
            // pageName: widget.dirName,
            configWatcher: gridSettings.watch,
            settingsButton: ShellSettingsButton.fromWatchable(
              gridSettings,
              header: const _ShowAdditionalButtons(),
              localizeHideNames: (context) =>
                  l10n.hideNames(l10n.hideNamesFiles),
            ),
            backButton: CallbackAppBarBackButton(
              onPressed: () {
                if (filter.filteringMode != FilteringMode.noFilter) {
                  filter.filteringMode = FilteringMode.noFilter;
                  return;
                }
                Navigator.pop(context);
              },
            ),
            appBar: SearchBarAppBarType.fromFilter(
              filter,
              hintText: widget.dirName,
              textEditingController: searchTextController,
              focus: searchFocus,
              complete: LocalTagsService.safe()?.complete,
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
                                    const GalleryService().trash.empty();
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
                // if (widget.callback != null)
                //   OnBooruTagPressed(
                //     onPressed: _onBooruTagPressed,
                //     child: Builder(
                //       builder: (context) => IconButton(
                //         onPressed: () {
                //           if (filter.progress.inRefreshing) {
                //             return;
                //           }

                //           final upTo = filter.backingStorage.count;

                //           try {
                //             final n = math.Random.secure().nextInt(upTo);

                //             filter.forIdxUnsafe(n).onPressed(context, n);
                //           } catch (e, trace) {
                //             Logger.root
                //                 .warning("getting random number", e, trace);

                //             return;
                //           }

                //           if (widget.callback!.returnBack) {
                //             Navigator.pop(context);
                //             Navigator.pop(context);
                //           }
                //         },
                //         icon: const Icon(Icons.casino_outlined),
                //       ),
                //     ),
                //   ),
              ],
            ),
            elements: [
              ElementPriority(
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
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                final selection = status.selection;

                                if (selection.count == filter.count) {
                                  selection.reset(true);
                                } else {
                                  selection.selectAll();
                                }
                              },
                              icon: const Icon(Icons.select_all_rounded),
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
                                  label: Text(l10n.enumFilteringModeDuplicate),
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
                hideOnEmpty: false,
              ),
              ElementPriority(
                Builder(
                  builder: (context) => ShellElement(
                    key: ValueKey(settings.filesExtendedActions),
                    state: status,
                    scrollingState: widget.scrollingState,
                    scrollUpOn: widget.navBarEvents == null
                        ? const []
                        : [(widget.navBarEvents!, null)],
                    registerNotifiers: (child) {
                      return ReturnFileCallbackNotifier(
                        callback: widget.callback,
                        child: FilesDataNotifier(
                          api: api,
                          child: DeleteDialogShowNotifier(
                            toShow: toShowDelete,
                            child: OnBooruTagPressed(
                              onPressed: _onBooruTagPressed,
                              child: filter.inject(
                                status.source.inject(child),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    slivers: [
                      CurrentGridSettingsLayout<File>(
                        source: filter.backingStorage,
                        progress: filter.progress,
                        // gridSeed: gridSeed,
                        selection: status.selection,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowAdditionalButtons extends StatefulWidget {
  const _ShowAdditionalButtons({
    super.key,
  });

  @override
  State<_ShowAdditionalButtons> createState() => __ShowAdditionalButtonsState();
}

class __ShowAdditionalButtonsState extends State<_ShowAdditionalButtons>
    with SettingsWatcherMixin {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SwitchListTile(
      value: settings.filesExtendedActions,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      onChanged: (value) => const SettingsService()
          .current
          .copy(filesExtendedActions: value)
          .save(),
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

  final PlatformImageViewStateImpl galleryDataImpl;

  static PlatformImageViewStateImpl of(BuildContext context) {
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
    this.onLongPress,
    this.items,
    this.showPin = true,
    this.emptyWidget = const SliverPadding(padding: EdgeInsets.zero),
    this.sliver = true,
    required this.tagNotifier,
  });

  final bool showPin;
  final bool sliver;

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

class _TagsRibbonState extends State<TagsRibbon> with TagManagerService {
  late final StreamSubscription<void>? pinnedSubscription;
  late final StreamSubscription<void> _events;

  final scrollController = ScrollController();

  late List<ImageTag> _list;
  late List<ImageTag>? _pinnedList = !widget.showPin
      ? null
      : pinned
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

    pinnedSubscription = !widget.showPin
        ? null
        : pinned.watch((_) {
            setState(() {
              _pinnedList = pinned
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
                    onDoubleTap: () {
                      if (pinned.exists(elem.tag)) {
                        pinned.delete(elem.tag);
                      } else {
                        pinned.add(elem.tag);
                      }

                      scrollController.animateTo(
                        0,
                        duration: Durations.medium1,
                        curve: Easing.standard,
                      );
                    },
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
    final selection = ShellSelectionHolder.of(context);

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
                    onPressed: selection.selectUnselectAll,
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
    this.gridSeed = 2,
    this.buildEmpty,
    required this.progress,
    required this.selection,
  });

  final bool hideThumbnails;

  final int gridSeed;

  final SourceStorage<int, T> source;
  final Widget Function(Object?)? buildEmpty;
  final RefreshingProgress progress;

  final ShellSelectionHolder? selection;

  @override
  Widget build(BuildContext context) {
    final config = ShellConfiguration.of(context);

    return switch (config.layoutType) {
      GridLayoutType.grid => GridLayout<T>(
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          selection: selection,
        ),
      GridLayoutType.list => ListLayout<T>(
          hideThumbnails: hideThumbnails,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          selection: selection,
        ),
      GridLayoutType.gridQuilted => QuiltedGridLayout<T>(
          randomNumber: gridSeed,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          selection: selection,
        ),
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

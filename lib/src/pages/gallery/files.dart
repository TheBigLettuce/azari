// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/booru/booru_restored_page.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files_filters.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/notifications.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/copy_move_preview.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_masonry_layout.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_quilted.dart";
import "package:gallery/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/make_tags.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/pause_video.dart";
import "package:gallery/src/widgets/search_bar/search_filter_grid.dart";
import "package:gallery/src/widgets/skeletons/grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

part "files_actions_mixin.dart";

bool _isSavingTags = false;

class GalleryFiles extends StatefulWidget {
  const GalleryFiles({
    super.key,
    required this.api,
    this.callback,
    required this.dirName,
    required this.bucketId,
    required this.secure,
    required this.generateGlue,
    required this.db,
    required this.tagManager,
  });

  final String dirName;
  final String bucketId;
  final GalleryAPIFiles api;
  final CallbackDescriptionNested? callback;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;
  final bool secure;

  final DbConn db;
  final TagManager tagManager;

  @override
  State<GalleryFiles> createState() => _GalleryFilesState();
}

class _GalleryFilesState extends State<GalleryFiles> with FilesActionsMixin {
  FavoriteFileService get favoriteFiles => widget.db.favoriteFiles;
  LocalTagsService get localTags => widget.db.localTags;
  WatchableGridSettingsData get gridSettings => widget.db.gridSettings.files;

  GalleryAPIFiles get api => widget.api;

  AppLifecycleListener? _listener;
  StreamSubscription<void>? _subscription;

  final miscSettings = MiscSettingsService.db().current;

  late final postTags = PostTags(localTags, widget.db.localTagDictionary);

  static const _log = LogTarget.gallery;

  final plug = chooseGalleryPlug();

  late final StreamSubscription<SettingsData?> settingsWatcher;

  // late final GalleryFilesExtra extra = widget.api.getExtra()
  //   ..setRefreshingStatusCallback((i, inRefresh, empty) {
  //     if (empty) {
  //       state.refreshingStatus.mutation.cellCount = 0;

  //       Navigator.of(context).pop();

  //       return;
  //     }

  //     state.gridKey.currentState?.selection.reset();

  //     if (!inRefresh) {
  //       mutation.isRefreshing = false;

  //       search.performSearch(search.searchTextController.text);

  //       setState(() {});
  //     }
  //   })
  //   ..setRefreshGridCallback(() {
  //     if (!mutation.isRefreshing) {
  //       mutation.isRefreshing = true;
  //       widget.api.refresh();
  //     }
  //   })
  //   ..setPassFilter((cells, data, end) {

  //     };
  //   });

  late final ChainedFilterResourceSource<int, GalleryFile> filter;

  late final GridSkeletonState<GalleryFile> state = GridSkeletonState();

  final searchTextController = TextEditingController();
  final searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    filter = ChainedFilterResourceSource(
      api.source,
      ListStorage(),
      prefilter: () {
        if (filter.filteringMode == FilteringMode.favorite) {
          _switcherKey.currentState?.setPage(2);
        } else {
          _switcherKey.currentState?.setPage(0);
        }

        if (filter.filteringMode == FilteringMode.same) {
          StatisticsGalleryService.db().current.add(sameFiltered: 1).save();
        }
      },
      filter: (cells, filteringMode, sortingMode, end, [data]) {
        return switch (filteringMode) {
          FilteringMode.favorite => FileFilters.favorite(cells, favoriteFiles),
          FilteringMode.untagged => FileFilters.untagged(cells, localTags),
          FilteringMode.tag =>
            FileFilters.tag(cells, searchTextController.text, postTags),
          FilteringMode.tagReversed =>
            FileFilters.tagReversed(cells, searchTextController.text, postTags),
          FilteringMode.video => FileFilters.video(cells),
          FilteringMode.gif => FileFilters.gif(cells),
          FilteringMode.duplicate => FileFilters.duplicate(cells),
          FilteringMode.original => FileFilters.original(cells, localTags),
          FilteringMode.same => FileFilters.same(
              context,
              cells,
              data,
              performSearch: () =>
                  api.source.clearRefreshSorting(filter.sortingMode),
              end: end,
              source: api.source,
            ),
          FilteringMode() => (cells, data),
        };

        // if (searchTextController.text.isNotEmpty &&
        //     (filteringMode != FilteringMode.tag &&
        //         filteringMode != FilteringMode.tagReversed)) {
        //   return e.name.contains(searchTextController.text);
        // }

        // return switch (filteringMode) {
        //   // FilteringMode.favorite => e.i,
        //   // FilteringMode.untagged => e.tagsFlat.isEmpty,
        //   FilteringMode.tag => localTags.cachedValues[e.name]
        //           ?.contains(searchTextController.text) ??
        //       false,
        //   // FilteringMode.tagReversed =>
        //   // !e.tagsFlat.contains(searchTextController.text),
        //   FilteringMode.video => e.isVideo,
        //   FilteringMode.gif => e.isGif,
        //   FilteringMode.duplicate => e.isDuplicate,
        //   // FilteringMode.original => e.isOriginal,
        //   FilteringMode.same => true,
        //   // FileFilters.same(
        //   //     context,
        //   //     cells,
        //   //     data,
        //   //     extra,
        //   //     getCell: (i) => widget.api.directCell(i - 1, true),
        //   //     performSearch: () =>
        //   //         search.performSearch(search.searchTextController.text),
        //   //     end: end,
        //   //   ),
        //   FilteringMode() => true,
        // };
      },
      allowedFilteringModes: {
        FilteringMode.noFilter,
        if (api.type != GalleryFilesPageType.favorites) FilteringMode.favorite,
        FilteringMode.original,
        FilteringMode.duplicate,
        FilteringMode.same,
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
      initialFilteringMode: FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    if (widget.secure) {
      _listener = AppLifecycleListener(
        onHide: () {
          _subscription?.cancel();
          _subscription = Stream<void>.periodic(const Duration(seconds: 10))
              .listen((event) {
            filter.backingStorage.clear();

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

      const AndroidApiFunctions().hideRecents(true);
    }

    api.source.clearRefreshSorting(filter.sortingMode);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _listener?.dispose();
    settingsWatcher.cancel();

    searchTextController.dispose();
    searchFocus.dispose();
    filter.destroy();

    api.close();
    state.dispose();

    const AndroidApiFunctions().hideRecents(false);

    super.dispose();
  }

  void _onBooruTagPressed(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? overrideSafeMode,
  ) {
    if (overrideSafeMode != null) {
      PauseVideoNotifier.maybePauseOf(context, true);

      final registry = PagingStateRegistry();

      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) {
            return BooruRestoredPage(
              booru: booru,
              tags: tag,
              pagingRegistry: registry,
              wrapScaffold: true,
              saveSelectedPage: (e) {},
              overrideSafeMode: overrideSafeMode,
              db: widget.db,
            );
          },
        ),
      ).then((value) {
        registry.dispose();
        PauseVideoNotifier.maybePauseOf(context, false);
      });

      return;
    }

    // Navigator.pop(context);

    searchTextController.text = tag;
    filter.filteringMode = FilteringMode.tag;
  }

  bool _filterFavorites(BuildContext context, int page) {
    switch (page) {
      case 1:
        final gridState = state.gridKey.currentState;

        if (gridState != null) {
          if (gridState.selection.count == gridState.source.count) {
            gridState.selection.reset(true);
          } else {
            gridState.selection.selectAll(context);
          }
        }

        return false;
      case 2:
        filter.filteringMode = FilteringMode.favorite;

        return true;
      default:
        filter.filteringMode = FilteringMode.noFilter;

        return true;
    }
  }

  final GlobalKey<ToggableLabelSwitcherWidgetState> _switcherKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GridConfiguration(
      watch: gridSettings.watch,
      child: WrapGridPage(
        addScaffold: widget.callback != null,
        provided: widget.generateGlue,
        child: GridSkeleton<GalleryFile>(
          state,
          (context) => GridFrame(
            key: state.gridKey,
            slivers: [
              CurrentGridSettingsLayout<GalleryFile>(
                source: filter.backingStorage,
                progress: filter.progress,
                gridSeed: state.gridSeed,
              ),
            ],
            functionality: GridFunctionality(
              settingsButton: GridSettingsButton.fromWatchable(gridSettings),
              registerNotifiers: (child) {
                return FilesDataNotifier(
                  actions: this,
                  api: widget.api,
                  nestedCallback: widget.callback,
                  child: OnBooruTagPressed(
                    onPressed: _onBooruTagPressed,
                    child: child,
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
              selectionGlue: GlueProvider.generateOf(context)(),
              source: filter,
              search: OverrideGridSearchWidget(
                SearchAndFocus(
                  FilteringSearchWidget(
                    hint: widget.dirName,
                    filter: filter,
                    textController: searchTextController,
                    localTagDictionary: widget.db.localTagDictionary,
                    focusNode: searchFocus,
                  ),
                  searchFocus,
                ),
              ),
            ),
            mainFocus: state.mainFocus,
            description: GridDescription(
              overrideEmptyWidgetNotice: api.type.isFavorites()
                  ? "Some files can't be shown"
                  : null, // TODO: change
              showPageSwitcherAsHeader: true,
              pages: api.type.isFavorites()
                  ? null
                  : PageSwitcherToggable(
                      [
                        PageToaggable(
                          Icons.select_all_rounded,
                          active: widget.callback == null,
                        ),
                        PageToaggable(FilteringMode.favorite.icon),
                      ],
                      _filterFavorites,
                      stateKey: _switcherKey,
                    ),
              actions: widget.callback != null
                  ? const []
                  : api.type.isTrash()
                      ? [
                          restoreFromTrash(),
                        ]
                      : [
                          if (api.type.isFavorites())
                            setFavoritesThumbnailAction(widget.db.miscSettings),
                          if (miscSettings.filesExtendedActions) ...[
                            bulkRename(),
                            saveTagsAction(plug, postTags, localTags),
                            addTag(
                              context,
                              () => api.source
                                  .clearRefreshSorting(filter.sortingMode),
                              localTags,
                            ),
                          ],
                          addToFavoritesAction(null, favoriteFiles),
                          deleteAction(),
                          copyAction(
                            widget.tagManager,
                            favoriteFiles,
                            localTags,
                          ),
                          moveAction(
                            widget.tagManager,
                            favoriteFiles,
                            localTags,
                          ),
                        ],
              menuButtonItems: [
                if (widget.callback == null && api.type.isTrash())
                  IconButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(
                        DialogRoute<void>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                AppLocalizations.of(context)!.emptyTrashTitle,
                              ),
                              content: Text(
                                AppLocalizations.of(context)!.thisIsPermanent,
                                style: TextStyle(
                                  color: Colors.red.harmonizeWith(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    GalleryManagementApi.current().emptyTrash();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.yes,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(AppLocalizations.of(context)!.no),
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
                  IconButton(
                    onPressed: () {
                      if (filter.progress.inRefreshing) {
                        return;
                      }

                      final upTo = filter.backingStorage.count;

                      try {
                        final n = math.Random.secure().nextInt(upTo);

                        final gridState = state.gridKey.currentState;
                        if (gridState != null) {
                          final cell = gridState.source.forIdxUnsafe(n);
                          cell.onPress(
                            context,
                            gridState.widget.functionality,
                            cell,
                            n,
                          );
                        }
                      } catch (e, trace) {
                        _log.logDefaultImportant(
                          "getting random number".errorMessage(e),
                          trace,
                        );

                        return;
                      }

                      if (widget.callback!.returnBack) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.casino_outlined),
                  ),
              ],

              inlineMenuButtonItems: true,
              bottomWidget: widget.callback != null
                  ? CopyMovePreview.hintWidget(
                      context,
                      AppLocalizations.of(context)!.chooseFileNotice,
                      widget.callback!.icon,
                    )
                  : null,
              keybindsDescription: widget.dirName,
              gridSeed: state.gridSeed,
            ),
          ),
          canPop: filter.filteringMode == FilteringMode.noFilter &&
              searchTextController.text.isEmpty,
          onPop: (pop) {
            if (searchTextController.text.isNotEmpty) {
              searchTextController.clear();
              // search.performSearch("");
              return;
            } else if (filter.filteringMode != FilteringMode.noFilter) {
              filter.filteringMode = FilteringMode.noFilter;
            }
          },
        ),
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
  });

  final SourceStorage<int, T> source;
  final bool hideThumbnails;
  final int gridSeed;
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
        ),
      GridLayoutType.list => ListLayout<T>(
          hideThumbnails: hideThumbnails,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
        ),
      GridLayoutType.gridQuilted => GridQuiltedLayout<T>(
          randomNumber: gridSeed,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
        ),
      GridLayoutType.gridMasonry => GridMasonryLayout(
          randomNumber: gridSeed,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
        ),
    };
  }
}

class FilesDataNotifier extends InheritedWidget {
  const FilesDataNotifier({
    super.key,
    required this.api,
    required this.actions,
    required this.nestedCallback,
    required super.child,
  });

  final GalleryAPIFiles api;
  final CallbackDescriptionNested? nestedCallback;
  final FilesActionsMixin actions;

  static (
    GalleryAPIFiles,
    CallbackDescriptionNested?,
    FilesActionsMixin,
  ) of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<FilesDataNotifier>();

    return (
      widget!.api,
      widget.nestedCallback,
      widget.actions,
    );
  }

  @override
  bool updateShouldNotify(FilesDataNotifier oldWidget) =>
      api != oldWidget.api ||
      nestedCallback != oldWidget.nestedCallback ||
      actions != oldWidget.actions;
}

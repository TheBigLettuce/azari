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
import "package:gallery/src/db/schemas/gallery/favorite_file.dart";
import "package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart";
import "package:gallery/src/db/schemas/grid_settings/files.dart";
import "package:gallery/src/db/schemas/settings/misc_settings.dart";
import "package:gallery/src/db/schemas/statistics/statistics_gallery.dart";
import "package:gallery/src/db/schemas/tags/pinned_tag.dart";
import "package:gallery/src/db/services/settings.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/filtering/filtering_interface.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/booru/booru_search_page.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files_filters.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/notifications.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/copy_move_preview.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_frame_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
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
  });

  final String dirName;
  final String bucketId;
  final GalleryAPIFiles api;
  final CallbackDescriptionNested? callback;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;
  final bool secure;

  @override
  State<GalleryFiles> createState() => _GalleryFilesState();
}

class _GalleryFilesState extends State<GalleryFiles> with FilesActionsMixin {
  static const _log = LogTarget.gallery;

  final plug = chooseGalleryPlug();

  late final StreamSubscription<SettingsData?> settingsWatcher;

  late final GalleryFilesExtra extra = widget.api.getExtra()
    ..setRefreshingStatusCallback((i, inRefresh, empty) {
      if (empty) {
        state.refreshingStatus.mutation.cellCount = 0;

        Navigator.of(context).pop();

        return;
      }

      state.gridKey.currentState?.selection.reset();

      if (!inRefresh) {
        mutation.isRefreshing = false;

        search.performSearch(search.searchTextController.text);

        setState(() {});
      }
    })
    ..setRefreshGridCallback(() {
      if (!mutation.isRefreshing) {
        mutation.isRefreshing = true;
        widget.api.refresh();
      }
    })
    ..setPassFilter((cells, data, end) {
      final filterMode = search.currentFilteringMode();

      return switch (filterMode) {
        FilteringMode.favorite => FileFilters.favorite(cells),
        FilteringMode.untagged => FileFilters.untagged(cells),
        FilteringMode.tag =>
          FileFilters.tag(cells, search.searchTextController.text),
        FilteringMode.notes => (
            cells.where((element) => element.notesFlat.isNotEmpty).where(
                  (element) => element.notesFlat
                      .contains(search.searchTextController.text.toLowerCase()),
                ),
            null
          ),
        FilteringMode.tagReversed =>
          FileFilters.tagReversed(cells, search.searchTextController.text),
        FilteringMode.video => FileFilters.video(cells),
        FilteringMode.gif => FileFilters.gif(cells),
        FilteringMode.duplicate => FileFilters.duplicate(cells),
        FilteringMode.original => FileFilters.original(cells),
        FilteringMode.same => FileFilters.same(
            context,
            cells,
            data,
            extra,
            getCell: (i) => widget.api.directCell(i - 1, true),
            performSearch: () =>
                search.performSearch(search.searchTextController.text),
            end: end,
          ),
        FilteringMode() => (cells, data),
      };
    });

  late final GridSkeletonStateFilter<SystemGalleryDirectoryFile> state =
      GridSkeletonStateFilter(
    transform: (cell) {
      if (state.filter.currentSortingMode == SortingMode.size ||
          search.currentFilteringMode() == FilteringMode.same) {
        cell.injectedStickers.add(cell.sizeSticker(cell.size));
      }

      return cell;
    },
    sortingModes: {
      SortingMode.none,
      SortingMode.size,
    },
    hook: (selected) {
      if (selected == FilteringMode.favorite) {
        _switcherKey.currentState?.setPage(1);
      } else {
        _switcherKey.currentState?.setPage(0);
      }

      if (selected == FilteringMode.same) {
        StatisticsGallery.addSameFiltered();
      }

      if (selected == FilteringMode.tag ||
          selected == FilteringMode.tagReversed ||
          selected == FilteringMode.notes) {
        search.markSearchVirtual();
      }

      setState(() {});
    },
    filter: extra.filter,
    filteringModes: {
      FilteringMode.noFilter,
      if (!extra.isFavorites) FilteringMode.favorite,
      FilteringMode.original,
      FilteringMode.duplicate,
      FilteringMode.same,
      FilteringMode.tag,
      FilteringMode.notes,
      FilteringMode.tagReversed,
      FilteringMode.untagged,
      FilteringMode.gif,
      FilteringMode.video,
    },
  );

  GridMutationInterface get mutation => state.refreshingStatus.mutation;

  late final SearchFilterGrid<SystemGalleryDirectoryFile> search;

  AppLifecycleListener? _listener;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    search = SearchFilterGrid(state, null);

    if (widget.secure) {
      _listener = AppLifecycleListener(
        onHide: () {
          _subscription?.cancel();
          _subscription =
              Stream.periodic(const Duration(seconds: 10)).listen((event) {
            state.refreshingStatus.mutation.cellCount = 0;

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

      PlatformFunctions.hideRecents(true);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _listener?.dispose();
    settingsWatcher.cancel();

    widget.api.close();
    search.dispose();
    state.dispose();

    PlatformFunctions.hideRecents(false);

    super.dispose();
  }

  void _refresh() {
    mutation.cellCount = 0;
    mutation.isRefreshing = true;
    widget.api.refresh();
  }

  void _onBooruTagPressed(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? overrideSafeMode,
  ) {
    if (overrideSafeMode != null) {
      PauseVideoNotifier.maybePauseOf(context, true);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return BooruSearchPage(
              booru: booru,
              tags: tag,
              wrapScaffold: true,
              overrideSafeMode: overrideSafeMode,
            );
          },
        ),
      ).then((value) => PauseVideoNotifier.maybePauseOf(context, false));

      return;
    }

    Navigator.pop(context);

    search.setFilteringMode(FilteringMode.tag);
    search.performSearch(tag);
  }

  bool _filterFavorites(BuildContext context, int page) {
    switch (page) {
      case 1:
        final gridState = state.gridKey.currentState;

        if (gridState != null) {
          if (gridState.selection.count == gridState.mutation.cellCount) {
            gridState.selection.reset(true);
          } else {
            gridState.selection.selectAll(context);
          }
        }

        return false;
      case 2:
        search
          ..setFilteringMode(FilteringMode.favorite)
          ..performSearch(search.searchTextController.text);

        return true;
      default:
        search
          ..setFilteringMode(FilteringMode.noFilter)
          ..performSearch(search.searchTextController.text);

        return true;
    }
  }

  final GlobalKey<ToggableLabelSwitcherWidgetState> _switcherKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return WrapGridPage(
      addScaffold: widget.callback != null,
      provided: widget.generateGlue,
      child: GridSkeleton<SystemGalleryDirectoryFile>(
        state,
        (context) => GridFrame(
          key: state.gridKey,
          layout: const GridSettingsLayoutBehaviour(GridSettingsFiles.current),
          getCell: (i) => state.transform(widget.api.directCell(i)),
          functionality: GridFunctionality(
            registerNotifiers: (child) {
              return FilesDataNotifier(
                actions: this,
                state: state,
                plug: plug,
                api: widget.api,
                nestedCallback: widget.callback,
                child: OnBooruTagPressed(
                  onPressed: _onBooruTagPressed,
                  child: child,
                ),
              );
            },
            watchLayoutSettings: GridSettingsFiles.watch,
            backButton: CallbackGridBackButton(
              onPressed: () {
                final filterMode = search.currentFilteringMode();
                if (filterMode != FilteringMode.noFilter) {
                  search.resetSearch();
                  return;
                }
                Navigator.pop(context);
              },
            ),
            selectionGlue: GlueProvider.generateOf(context)(),
            refreshingStatus: state.refreshingStatus,
            refresh: extra.supportsDirectRefresh
                ? AsyncGridRefresh(() async {
                    final i = await widget.api.refresh();

                    search.performSearch(search.searchTextController.text);

                    return i;
                  })
                : RetainedGridRefresh(_refresh),
            search: OverrideGridSearchWidget(
              SearchAndFocus(
                search.searchWidget(context, hint: widget.dirName),
                search.searchFocus,
              ),
            ),
          ),
          mainFocus: state.mainFocus,
          description: GridDescription(
            overrideEmptyWidgetNotice:
                extra.isFavorites ? "Some files can't be shown" : null,
            showPageSwitcherAsHeader: true,
            pages: extra.isFavorites
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
                : extra.isTrash
                    ? [
                        restoreFromTrash(),
                      ]
                    : [
                        if (extra.isFavorites) setFavoritesThumbnailAction(),
                        if (MiscSettings.current.filesExtendedActions) ...[
                          bulkRename(),
                          saveTagsAction(plug),
                          addTag(context, () {
                            state.gridKey.currentState?.refreshSequence();
                          }),
                        ],
                        addToFavoritesAction(null, plug),
                        deleteAction(),
                        copyAction(state, plug),
                        moveAction(state, plug),
                      ],
            menuButtonItems: [
              if (widget.callback == null && extra.isTrash)
                IconButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      DialogRoute(
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
                                  PlatformFunctions.emptyTrash();
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
                    if (state.gridKey.currentState?.mutation.isRefreshing !=
                        false) {
                      return;
                    }

                    final upTo = state.gridKey.currentState?.mutation.cellCount;
                    if (upTo == null) {
                      return;
                    }

                    try {
                      final n = math.Random.secure().nextInt(upTo);

                      widget.callback
                          ?.call(state.gridKey.currentState!.widget.getCell(n));
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
            settingsButton: GridFrameSettingsButton(
              selectRatio: (ratio, settings) => (settings as GridSettingsFiles)
                  .copy(aspectRatio: ratio)
                  .save(),
              selectHideName: (hideNames, settings) =>
                  (settings as GridSettingsFiles)
                      .copy(hideName: hideNames)
                      .save(),
              selectGridLayout: (layoutType, settings) =>
                  (settings as GridSettingsFiles)
                      .copy(layoutType: layoutType)
                      .save(),
              selectGridColumn: (columns, settings) =>
                  (settings as GridSettingsFiles).copy(columns: columns).save(),
            ),
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
        canPop: search.currentFilteringMode() == FilteringMode.noFilter &&
            search.searchTextController.text.isEmpty,
        onPop: (pop) {
          final filterMode = search.currentFilteringMode();
          if (search.searchTextController.text.isNotEmpty) {
            search.performSearch("");
            return;
          } else if (filterMode != FilteringMode.noFilter) {
            search.resetSearch();
          }
        },
      ),
    );
  }
}

class FilesDataNotifier extends InheritedWidget {
  const FilesDataNotifier({
    super.key,
    required this.api,
    required this.actions,
    required this.nestedCallback,
    required this.plug,
    required this.state,
    required super.child,
  });

  final GalleryAPIFiles api;
  final CallbackDescriptionNested? nestedCallback;
  final FilesActionsMixin actions;
  final GridSkeletonStateFilter<SystemGalleryDirectoryFile> state;
  final GalleryPlug plug;

  static (
    GalleryAPIFiles,
    CallbackDescriptionNested?,
    FilesActionsMixin,
    GridSkeletonStateFilter<SystemGalleryDirectoryFile>,
    GalleryPlug,
  ) of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<FilesDataNotifier>();

    return (
      widget!.api,
      widget.nestedCallback,
      widget.actions,
      widget.state,
      widget.plug,
    );
  }

  @override
  bool updateShouldNotify(FilesDataNotifier oldWidget) =>
      api != oldWidget.api ||
      nestedCallback != oldWidget.nestedCallback ||
      actions != oldWidget.actions ||
      plug != oldWidget.plug ||
      state != oldWidget.state;
}

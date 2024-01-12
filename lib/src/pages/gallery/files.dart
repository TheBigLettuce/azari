// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'dart:math' as math;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/grid_settings/files.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/db/schemas/gallery/note_gallery.dart';
import 'package:gallery/src/db/schemas/gallery/pinned_thumbnail.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_gallery.dart';
import 'package:gallery/src/interfaces/gallery/gallery_api_files.dart';
import 'package:gallery/src/interfaces/gallery/gallery_files_extra.dart';
import 'package:gallery/src/logging/logging.dart';
import 'package:gallery/src/pages/booru/grid_settings_button.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/pages/gallery/directories.dart';
import 'package:gallery/src/plugs/notifications.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart';
import 'package:gallery/src/db/schemas/gallery/favorite_media.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/layouts/grid_layout.dart';
import 'package:gallery/src/widgets/grid/layouts/list_layout.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/schemas/settings/settings.dart';
import '../../db/schemas/gallery/system_gallery_directory.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../interfaces/filtering/sorting_mode.dart';
import '../../plugs/gallery.dart';
import '../../widgets/copy_move_preview.dart';
import '../../widgets/grid/wrap_grid_page.dart';
import '../../widgets/search_bar/search_filter_grid.dart';
import '../../interfaces/filtering/filters.dart';
import '../../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../../widgets/skeletons/grid_skeleton.dart';
import 'callback_description.dart';
import 'callback_description_nested.dart';

part 'files_actions_mixin.dart';

bool _isSavingTags = false;

class GalleryFiles extends StatefulWidget {
  final String dirName;
  final String bucketId;
  final GalleryAPIFiles api;
  final CallbackDescriptionNested? callback;

  const GalleryFiles(
      {super.key,
      required this.api,
      this.callback,
      required this.dirName,
      required this.bucketId});

  @override
  State<GalleryFiles> createState() => _GalleryFilesState();
}

class _GalleryFilesState extends State<GalleryFiles>
    with SearchFilterGrid<SystemGalleryDirectoryFile>, _FilesActionsMixin {
  static const _log = LogTarget.gallery;

  final stream = StreamController<int>(sync: true);

  final plug = chooseGalleryPlug();

  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription<GridSettingsFiles?> gridSettingsWatcher;

  GridSettingsFiles gridSettings = GridSettingsFiles.current;

  late final GalleryFilesExtra extra = widget.api.getExtra()
    ..setRefreshingStatusCallback((i, inRefresh, empty) {
      if (empty) {
        // state.gridKey.currentState?.selection.currentBottomSheet?.close();
        state.gridKey.currentState?.imageViewKey.currentState?.key.currentState
            ?.closeEndDrawer();
        final imageViewContext =
            state.gridKey.currentState?.imageViewKey.currentContext;
        if (imageViewContext != null) {
          Navigator.of(imageViewContext).pop();
        }

        Navigator.of(context).pop();

        return;
      }

      state.gridKey.currentState?.mutationInterface.unselectAll();

      stream.add(i);

      if (!inRefresh) {
        state.gridKey.currentState?.mutationInterface.setIsRefreshing(false);

        performSearch(searchTextController.text);
        if (i == 1) {
          state.gridKey.currentState?.imageViewKey.currentState?.hardRefresh();
        }
        setState(() {});
      }
    })
    ..setRefreshGridCallback(() {
      if (state.gridKey.currentState?.mutationInterface.isRefreshing == false) {
        _refresh();
      }
    })
    ..setPassFilter((cells, data, end) {
      final filterMode = currentFilteringMode();

      return switch (filterMode) {
        FilteringMode.favorite => Filters.favorite(cells),
        FilteringMode.untagged => Filters.untagged(cells),
        FilteringMode.tag => Filters.tag(cells, searchTextController.text),
        FilteringMode.notes => (
            cells.where((element) => element.notesFlat.isNotEmpty).where(
                (element) => element.notesFlat
                    .contains(searchTextController.text.toLowerCase())),
            null
          ),
        FilteringMode.tagReversed =>
          Filters.tagReversed(cells, searchTextController.text),
        FilteringMode.video => Filters.video(cells),
        FilteringMode.gif => Filters.gif(cells),
        FilteringMode.duplicate => Filters.duplicate(cells),
        FilteringMode.original => Filters.original(cells),
        FilteringMode.same => Filters.same(
            context,
            cells,
            data,
            extra,
            getCell: (i) => widget.api.directCell(i - 1),
            performSearch: () => performSearch(searchTextController.text),
            end: end,
          ),
        FilteringMode() => (cells, data),
      };
    });

  late final GridSkeletonStateFilter<SystemGalleryDirectoryFile> state =
      GridSkeletonStateFilter(
    transform: (cell, sorting) {
      if (sorting == SortingMode.size ||
          currentFilteringMode() == FilteringMode.same) {
        cell.injectedStickers.add(cell.sizeSticker());
      }

      return cell;
    },
    hook: (selected) {
      if (selected == FilteringMode.same) {
        StatisticsGallery.addSameFiltered();
      }

      if (selected == FilteringMode.tag ||
          selected == FilteringMode.tagReversed ||
          selected == FilteringMode.notes) {
        markSearchVirtual();
      }

      setState(() {});

      if (selected == FilteringMode.size) {
        return SortingMode.size;
      }

      return SortingMode.none;
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
      FilteringMode.size,
      FilteringMode.video
    },
  );

  @override
  void initState() {
    super.initState();

    gridSettingsWatcher = GridSettingsFiles.watch((newSettings) {
      gridSettings = newSettings!;

      setState(() {});
    });

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;

      setState(() {});
    });
    searchHook(state);
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    gridSettingsWatcher.cancel();

    widget.api.close();
    stream.close();
    disposeSearch();
    state.dispose();
    super.dispose();
  }

  void _refresh() {
    stream.add(0);
    state.gridKey.currentState?.mutationInterface.setIsRefreshing(true);
    widget.api.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.of(context).viewPadding;

    return WrapGridPage<SystemGalleryDirectoryFile>(
        scaffoldKey: state.scaffoldKey,
        child: GridSkeleton<SystemGalleryDirectoryFile>(
          state,
          (context) => CallbackGrid(
              key: state.gridKey,
              getCell: (i) => widget.api.directCell(i),
              initalScrollPosition: 0,
              scaffoldKey: state.scaffoldKey,
              systemNavigationInsets: viewPadding,
              hasReachedEnd: () => true,
              addFabPadding: true,
              selectionGlue: GlueProvider.of(context),
              statistics: const ImageViewStatistics(
                  swiped: StatisticsGallery.addFilesSwiped,
                  viewed: StatisticsGallery.addViewedFiles),
              addIconsImage: (cell) {
                return widget.callback != null
                    ? [
                        _chooseAction(),
                      ]
                    : extra.isTrash
                        ? [
                            _restoreFromTrash(),
                          ]
                        : [
                            if (MiscSettings.current.filesExtendedActions &&
                                cell.isVideo)
                              _loadVideoThumbnailAction(state),
                            _addToFavoritesAction(cell, plug),
                            _deleteAction(),
                            _copyAction(state, plug),
                            _moveAction(state, plug)
                          ];
              },
              showCount: true,
              searchWidget: SearchAndFocus(
                  searchWidget(context, hint: widget.dirName), searchFocus),
              mainFocus: state.mainFocus,
              refresh: extra.supportsDirectRefresh
                  ? () async {
                      final i = await widget.api.refresh();

                      performSearch(searchTextController.text);

                      return i;
                    }
                  : () {
                      _refresh();
                      return null;
                    },
              menuButtonItems: [
                if (widget.callback == null && extra.isTrash)
                  IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            DialogRoute(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .emptyTrashTitle),
                                    content: Text(
                                      AppLocalizations.of(context)!
                                          .thisIsPermanent,
                                      style: TextStyle(
                                          color: Colors.red.harmonizeWith(
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary)),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            PlatformFunctions.emptyTrash();
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .yes)),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                              AppLocalizations.of(context)!.no))
                                    ],
                                  );
                                }));
                      },
                      icon: const Icon(Icons.delete_sweep_outlined)),
                if (widget.callback != null)
                  IconButton(
                      onPressed: () {
                        if (state.gridKey.currentState?.mutationInterface
                                .isRefreshing !=
                            false) {
                          return;
                        }

                        final upTo = state
                            .gridKey.currentState?.mutationInterface.cellCount;
                        if (upTo == null) {
                          return;
                        }

                        try {
                          final n = math.Random.secure().nextInt(upTo);

                          widget.callback?.call(state
                              .gridKey.currentState!.mutationInterface
                              .getCell(n));
                        } catch (e, trace) {
                          _log.logDefaultImportant(
                              "getting random number".errorMessage(e), trace);

                          return;
                        }

                        if (widget.callback!.returnBack) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.casino_outlined)),
                GridSettingsButton(gridSettings,
                    selectRatio: (ratio) =>
                        gridSettings.copy(aspectRatio: ratio).save(),
                    selectHideName: (hideNames) =>
                        gridSettings.copy(hideName: hideNames).save(),
                    selectListView: (listView) =>
                        gridSettings.copy(listView: listView).save(),
                    selectGridColumn: (columns) =>
                        gridSettings.copy(columns: columns).save()),
              ],
              inlineMenuButtonItems: true,
              noteInterface: NoteGallery.interface((
                  {int? replaceIndx, bool addNote = false, int? removeNote}) {
                if (state
                        .gridKey.currentState?.mutationInterface.isRefreshing ==
                    true) {
                  return;
                }

                _refresh();
              }),
              onBack: () {
                final filterMode = currentFilteringMode();
                if (filterMode != FilteringMode.noFilter) {
                  resetSearch();
                  return;
                }
                Navigator.pop(context);
              },
              progressTicker: stream.stream,
              description: GridDescription(
                  widget.callback != null
                      ? []
                      : extra.isTrash
                          ? [
                              _restoreFromTrash(),
                            ]
                          : [
                              if (extra.isFavorites)
                                _setFavoritesThumbnailAction(),
                              if (MiscSettings
                                  .current.filesExtendedActions) ...[
                                _bulkRename(),
                                _saveTagsAction(plug),
                              ],
                              _addToFavoritesAction(null, plug),
                              _deleteAction(),
                              _copyAction(state, plug),
                              _moveAction(state, plug),
                            ],
                  bottomWidget: widget.callback != null
                      ? CopyMovePreview.hintWidget(context,
                          AppLocalizations.of(context)!.chooseFileNotice)
                      : null,
                  keybindsDescription: widget.dirName,
                  layout: gridSettings.listView
                      ? const ListLayout()
                      : GridLayout(
                          gridSettings.columns,
                          gridSettings.aspectRatio,
                          tightMode: true,
                          hideAlias: gridSettings.hideName,
                        ))),
          noDrawer: widget.callback != null,
          canPop: currentFilteringMode() == FilteringMode.noFilter &&
              searchTextController.text.isEmpty,
          overrideOnPop: (pop, hideAppBar) {
            final filterMode = currentFilteringMode();
            if (filterMode != FilteringMode.noFilter ||
                searchTextController.text.isNotEmpty) {
              resetSearch();
              setState(() {});
              return;
            }

            if (hideAppBar()) {
              setState(() {});
              return;
            }
          },
        ));
  }
}

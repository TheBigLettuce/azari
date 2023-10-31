// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gallery/src/db/post_tags.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/note_gallery.dart';
import 'package:gallery/src/plugs/platform_channel.dart';
import 'package:gallery/src/pages/gallery/directories.dart';
import 'package:gallery/src/interfaces/gallery.dart';
import 'package:gallery/src/pages/booru/main.dart';
import 'package:gallery/src/plugs/notifications.dart';
import 'package:gallery/src/db/schemas/system_gallery_directory_file.dart';
import 'package:gallery/src/db/schemas/favorite_media.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/schemas/settings.dart';
import '../../db/schemas/system_gallery_directory.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../../interfaces/filtering/sorting_mode.dart';
import '../../plugs/gallery.dart';
import '../../widgets/copy_move_preview.dart';
import '../../widgets/grid/wrap_grid_page.dart';
import '../../widgets/search_bar/search_filter_grid.dart';
import '../../plugs/gallery/android/filters.dart';
import '../../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../../widgets/skeletons/make_grid_skeleton.dart';

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
    with SearchFilterGrid<SystemGalleryDirectoryFile> {
  final stream = StreamController<int>(sync: true);

  final plug = chooseGalleryPlug();

  late final StreamSubscription<Settings?> settingsWatcher;
  bool proceed = true;

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

      state.gridKey.currentState?.mutationInterface?.unselectAll();

      stream.add(i);

      if (!inRefresh) {
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);

        performSearch(searchTextController.text);
        if (i == 1) {
          state.gridKey.currentState?.imageViewKey.currentState?.hardRefresh();
        }
        setState(() {});
      }
    })
    ..setRefreshGridCallback(() {
      if (state.gridKey.currentState?.mutationInterface?.isRefreshing ==
          false) {
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
      if (selected == FilteringMode.tag ||
          selected == FilteringMode.tagReversed ||
          selected == FilteringMode.notes) {
        markSearchVirtual();
      }

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

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;

      setState(() {});
    });
    searchHook(state);
  }

  @override
  void dispose() {
    widget.api.close();
    stream.close();
    settingsWatcher.cancel();
    disposeSearch();
    state.dispose();
    super.dispose();
  }

  void _refresh() {
    stream.add(0);
    state.gridKey.currentState?.mutationInterface?.setIsRefreshing(true);
    widget.api.refresh();
  }

  void _moveOrCopy(BuildContext context,
      List<SystemGalleryDirectoryFile> selected, bool move) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return WrappedGridPage<SystemGalleryDirectory>(
            scaffoldKey: GlobalKey(),
            f: (glue) => GalleryDirectories(
                  showBackButton: true,
                  glue: glue,
                  procPop: (_) {},
                  callback: CallbackDescription(
                      move
                          ? AppLocalizations.of(context)!.chooseMoveDestination
                          : AppLocalizations.of(context)!.chooseCopyDestination,
                      (chosen, newDir) {
                    if (chosen == null && newDir == null) {
                      throw "both are empty";
                    }

                    if (chosen != null && chosen.bucketId == widget.bucketId) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(move
                              ? AppLocalizations.of(context)!.cantMoveSameDest
                              : AppLocalizations.of(context)!
                                  .cantCopySameDest)));
                      return Future.value();
                    }

                    if (chosen?.bucketId == "favorites") {
                      _favoriteOrUnfavorite(context, selected);
                    } else if (chosen?.bucketId == "trash") {
                      if (!move) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text(
                          "Can't copy files to the trash. Use move.", // TODO: change
                        )));
                        return Future.value();
                      }

                      return _deleteDialog(context, selected);
                    } else {
                      PlatformFunctions.copyMoveFiles(
                          chosen?.relativeLoc, chosen?.volumeName, selected,
                          move: move, newDir: newDir);
                    }

                    return Future.value();
                  },
                      preview: PreferredSize(
                        preferredSize: const Size.fromHeight(52),
                        child: CopyMovePreview(
                          files: selected,
                          size: 52,
                        ),
                      ),
                      joinable: false),
                ));
      },
    ));
  }

  void _favoriteOrUnfavorite(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    for (final fav in selected) {
      if (fav.isFavorite()) {
        Dbs.g.blacklisted.writeTxnSync(
            () => Dbs.g.blacklisted.favoriteMedias.deleteSync(fav.id));
      } else {
        Dbs.g.blacklisted.writeTxnSync(() =>
            Dbs.g.blacklisted.favoriteMedias.putSync(FavoriteMedia(fav.id)));
      }
    }

    plug.notify(null);
  }

  void _saveTags(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) async {
    if (_isSavingTags) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.tagSavingInProgress)));
      return;
    }
    _isSavingTags = true;

    final notifi = await chooseNotificationPlug().newProgress(
        "${AppLocalizations.of(context)!.savingTagsSaving}"
            " ${selected.length == 1 ? '1 ${AppLocalizations.of(context)!.tagSingular}' : '${selected.length} ${AppLocalizations.of(context)!.tagPlural}'}",
        -10,
        "Saving tags",
        AppLocalizations.of(context)!.savingTags);
    notifi.setTotal(selected.length);

    for (final (i, elem) in selected.indexed) {
      notifi.update(i, "$i/${selected.length}");

      if (PostTags.g.getTagsPost(elem.name).isEmpty) {
        await PostTags.g.getOnlineAndSaveTags(elem.name);
      }
    }
    notifi.done();
    plug.notify(null);
    _isSavingTags = false;
  }

  void _changeName(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    if (selected.isEmpty) {
      return;
    }
    Navigator.push(
        context,
        DialogRoute(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.bulkRenameTitle),
              content: TextFormField(
                autofocus: true,
                initialValue: "*",
                autovalidateMode: AutovalidateMode.always,
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context)!.valueIsNull;
                  }
                  if (value.isEmpty) {
                    return AppLocalizations.of(context)!.newNameShouldntBeEmpty;
                  }

                  if (!value.contains("*")) {
                    return AppLocalizations.of(context)!
                        .newNameShouldIncludeOneStar;
                  }

                  return null;
                },
                onFieldSubmitted: (value) async {
                  if (value.isEmpty) {
                    return;
                  }
                  final idx = value.indexOf("*");
                  if (idx == -1) {
                    return;
                  }

                  final matchBefore = value.substring(0, idx);

                  for (final (i, e) in selected.indexed) {
                    PlatformFunctions.rename(
                        e.originalUri, "$matchBefore${e.name}",
                        notify: i == selected.length - 1);
                  }

                  Navigator.pop(context);
                },
              ),
            );
          },
        ));
  }

  Future<void> _deleteDialog(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    return Navigator.push(
        context,
        DialogRoute(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(selected.length == 1
                  ? "${AppLocalizations.of(context)!.tagDeleteDialogTitle} ${selected.first.name}"
                  : "${AppLocalizations.of(context)!.tagDeleteDialogTitle}"
                      " ${selected.length}"
                      " ${AppLocalizations.of(context)!.itemPlural}"),
              content:
                  Text(AppLocalizations.of(context)!.youCanRestoreFromTrash),
              actions: [
                TextButton(
                    onPressed: () {
                      PlatformFunctions.addToTrash(
                          selected.map((e) => e.originalUri).toList());
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.yes)),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.no))
              ],
            );
          },
        ));
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _restoreFromTrash() {
    return GridBottomSheetAction(
      Icons.restore_from_trash,
      (selected) {
        PlatformFunctions.removeFromTrash(
            selected.map((e) => e.originalUri).toList());
      },
      false,
    );
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _bulkRename() {
    return GridBottomSheetAction(
      Icons.edit,
      (selected) {
        _changeName(context, selected);
      },
      false,
    );
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _saveTagsAction() {
    return GridBottomSheetAction(
      Icons.tag_rounded,
      (selected) {
        _saveTags(context, selected);
      },
      true,
    );
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _addToFavoritesAction(
      SystemGalleryDirectoryFile? f) {
    final isFavorites = f != null && f.isFavorite();

    return GridBottomSheetAction(
        isFavorites ? Icons.star_rounded : Icons.star_border_rounded,
        (selected) {
      _favoriteOrUnfavorite(context, selected);
    }, false,
        color: isFavorites ? Colors.yellow.shade900 : null,
        animate: f != null,
        play: !isFavorites);
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _deleteAction() {
    return GridBottomSheetAction(
      Icons.delete,
      (selected) {
        _deleteDialog(context, selected);
      },
      false,
    );
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _copyAction() {
    return GridBottomSheetAction(
      Icons.copy,
      (selected) {
        _moveOrCopy(context, selected, false);
      },
      false,
    );
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _moveAction() {
    return GridBottomSheetAction(
      Icons.forward,
      (selected) {
        _moveOrCopy(context, selected, true);
      },
      false,
    );
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _chooseAction() {
    return GridBottomSheetAction(
      Icons.check,
      (selected) {
        widget.callback!(selected.first);
        if (widget.callback!.returnBack) {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        }
      },
      false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WrappedGridPage<SystemGalleryDirectoryFile>(
        scaffoldKey: state.scaffoldKey,
        f: (glue) => makeGridSkeleton<SystemGalleryDirectoryFile>(
              context,
              state,
              CallbackGrid(
                  key: state.gridKey,
                  getCell: (i) => widget.api.directCell(i),
                  initalScrollPosition: 0,
                  scaffoldKey: state.scaffoldKey,
                  systemNavigationInsets:
                      MediaQuery.of(context).systemGestureInsets,
                  hasReachedEnd: () => true,
                  immutable: false,
                  addFabPadding: true,
                  selectionGlue: glue,
                  tightMode: true,
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
                                _addToFavoritesAction(cell),
                                _deleteAction(),
                                _copyAction(),
                                _moveAction()
                              ];
                  },
                  aspectRatio: state.settings.galleryFiles.aspectRatio.value,
                  hideAlias: state.settings.galleryFiles.hideName,
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
                    if (widget.callback != null)
                      IconButton(
                          onPressed: () {
                            if (state.gridKey.currentState?.mutationInterface
                                    ?.isRefreshing !=
                                false) {
                              return;
                            }

                            final upTo = state.gridKey.currentState
                                ?.mutationInterface?.cellCount;
                            if (upTo == null) {
                              return;
                            }

                            try {
                              final n = math.Random.secure().nextInt(upTo);

                              widget.callback?.call(state
                                  .gridKey.currentState!.mutationInterface!
                                  .getCell(n));
                            } catch (e) {
                              log("getting random number",
                                  level: Level.WARNING.value, error: e);
                              return;
                            }

                            if (widget.callback!.returnBack) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.casino_outlined)),
                    gridSettingsButton(state.settings.galleryFiles,
                        selectRatio: (ratio) => state.settings
                            .copy(
                                galleryFiles: state.settings.galleryFiles
                                    .copy(aspectRatio: ratio))
                            .save(),
                        selectHideName: (hideNames) => state.settings
                            .copy(
                                galleryFiles: state.settings.galleryFiles
                                    .copy(hideName: hideNames))
                            .save(),
                        selectListView: (listView) => state.settings
                            .copy(
                                galleryFiles: state.settings.galleryFiles
                                    .copy(listView: listView))
                            .save(),
                        selectGridColumn: (columns) => state.settings
                            .copy(
                                galleryFiles: state.settings.galleryFiles
                                    .copy(columns: columns))
                            .save()),
                  ],
                  inlineMenuButtonItems: true,
                  noteInterface: NoteGallery.interface((
                      {int? replaceIndx,
                      bool addNote = false,
                      int? removeNote}) {
                    if (state.gridKey.currentState?.mutationInterface
                            ?.isRefreshing ==
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
                                  _bulkRename(),
                                  _saveTagsAction(),
                                  _addToFavoritesAction(null),
                                  _deleteAction(),
                                  _copyAction(),
                                  _moveAction(),
                                ],
                      state.settings.galleryFiles.columns,
                      listView: state.settings.galleryFiles.listView,
                      bottomWidget: widget.callback != null
                          ? CopyMovePreview.hintWidget(context,
                              AppLocalizations.of(context)!.chooseFileNotice)
                          : null,
                      keybindsDescription: widget.dirName)),
              noDrawer: widget.callback != null,
              canPop: currentFilteringMode() == FilteringMode.noFilter &&
                  searchTextController.text.isEmpty &&
                  !glue.isOpen() &&
                  state.gridKey.currentState?.showSearchBar == false,
              overrideOnPop: (pop, hideAppBar) {
                final filterMode = currentFilteringMode();
                if (filterMode != FilteringMode.noFilter ||
                    searchTextController.text.isNotEmpty) {
                  resetSearch();
                  setState(() {});
                  return;
                }

                if (glue.isOpen()) {
                  state.gridKey.currentState?.selection.reset();
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

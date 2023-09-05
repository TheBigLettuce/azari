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
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/gallery/android_api/android_directories.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/plugs/notifications.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/favorite_media.dart';
import 'package:gallery/src/widgets/copy_move_hint_text.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';
import '../../schemas/settings.dart';
import '../../widgets/copy_move_preview.dart';
import '../../widgets/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'filters.dart';

class AndroidFiles extends StatefulWidget {
  final String dirName;
  final String bucketId;
  final GalleryAPIFiles<AndroidGalleryFilesExtra, SystemGalleryDirectoryFile>
      api;
  final CallbackDescriptionNested? callback;
  const AndroidFiles(
      {super.key,
      required this.api,
      this.callback,
      required this.dirName,
      required this.bucketId});

  @override
  State<AndroidFiles> createState() => _AndroidFilesState();
}

class _AndroidFilesState extends State<AndroidFiles>
    with SearchFilterGrid<SystemGalleryDirectoryFile> {
  final stream = StreamController<int>(sync: true);

  late final StreamSubscription<Settings?> settingsWatcher;
  bool proceed = true;

  late final AndroidGalleryFilesExtra extra = widget.api.getExtra()
    ..setRefreshingStatusCallback((i, inRefresh, empty) {
      if (empty && !extra.isTrash() && !extra.isFavorites()) {
        state.gridKey.currentState?.selection.currentBottomSheet?.close();
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
        state.gridKey.currentState?.imageViewKey.currentState
            ?.update(state.gridKey.currentState!.mutationInterface!.cellCount);
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);
        performSearch(searchTextController.text);
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
      return switch (currentFilteringMode()) {
        FilteringMode.noFilter => (cells, data),
        FilteringMode.size => (cells, data),
        FilteringMode.favorite => Filters.favorite(cells),
        FilteringMode.untagged => Filters.untagged(cells),
        FilteringMode.tag => Filters.tag(cells, searchTextController.text),
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
                selected == FilteringMode.tagReversed) {
              markSearchVirtual();
            }

            if (selected == FilteringMode.size) {
              return SortingMode.size;
            }

            return SortingMode.none;
          },
          filter: extra.filter,
          index: kGalleryDrawerIndex,
          filteringModes: {
            FilteringMode.noFilter,
            if (!extra.isFavorites()) FilteringMode.favorite,
            FilteringMode.original,
            FilteringMode.duplicate,
            FilteringMode.same,
            FilteringMode.tag,
            FilteringMode.tagReversed,
            FilteringMode.untagged,
            FilteringMode.gif,
            FilteringMode.size,
            FilteringMode.video
          },
          onWillPop: () => Future.value(true));

  @override
  void initState() {
    super.initState();

    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      state.settings = event!;

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
        return AndroidDirectories(
          showBackButton: true,
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
                      : AppLocalizations.of(context)!.cantCopySameDest)));
              return;
            }

            PlatformFunctions.copyMoveFiles(
                chosen?.relativeLoc, chosen?.volumeName, selected,
                move: move, newDir: newDir);
          },
              preview: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: CopyMovePreview(
                  files: selected,
                ),
              )),
        );
      },
    ));
  }

  void _favoriteOrUnfavorite(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    for (final fav in selected) {
      if (fav.isFavorite()) {
        blacklistedDirIsar().writeTxnSync(
            () => blacklistedDirIsar().favoriteMedias.deleteSync(fav.id));
      } else {
        blacklistedDirIsar().writeTxnSync(() =>
            blacklistedDirIsar().favoriteMedias.putSync(FavoriteMedia(fav.id)));
      }
    }

    _refresh();
  }

  void _saveTags(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) async {
    if (GalleryImpl.instance().isSavingTags) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.tagSavingInProgress)));
      return;
    }
    GalleryImpl.instance().isSavingTags = true;

    final notifi = await chooseNotificationPlug().newProgress(
        "${AppLocalizations.of(context)!.savingTagsSaving}"
            " ${selected.length == 1 ? '1 ${AppLocalizations.of(context)!.tagSingular}' : '${selected.length} ${AppLocalizations.of(context)!.tagPlural}'}",
        -10,
        "Saving tags",
        AppLocalizations.of(context)!.savingTags);
    notifi.setTotal(selected.length);

    for (final (i, elem) in selected.indexed) {
      notifi.update(i, "$i/${selected.length}");

      if (PostTags().getTagsPost(elem.name).isEmpty) {
        await PostTags().getOnlineAndSaveTags(elem.name);
      }
    }
    notifi.done();
    GalleryImpl.instance().notify(null);
    GalleryImpl.instance().isSavingTags = false;
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

  void _deleteDialog(
      BuildContext context, List<SystemGalleryDirectoryFile> selected) {
    Navigator.push(
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
    return GridBottomSheetAction(Icons.restore_from_trash, (selected) {
      PlatformFunctions.removeFromTrash(
          selected.map((e) => e.originalUri).toList());
    },
        false,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.restoreActionLabel,
          body: AppLocalizations.of(context)!.restoreActionBody,
        ));
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _bulkRename() {
    return GridBottomSheetAction(Icons.edit, (selected) {
      _changeName(context, selected);
    },
        false,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.bulkRenameTitle,
          body: AppLocalizations.of(context)!.bulkRenameActionBody,
        ));
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _saveTagsAction() {
    return GridBottomSheetAction(Icons.tag_rounded, (selected) {
      _saveTags(context, selected);
    },
        true,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.savingTags,
          body: AppLocalizations.of(context)!.saveTagsActionBody,
        ));
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _addToFavoritesAction() {
    return GridBottomSheetAction(Icons.star_border_outlined, (selected) {
      _favoriteOrUnfavorite(context, selected);
    },
        false,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.favoritesActionLabel,
          body: AppLocalizations.of(context)!.favoritesActionBody,
        ));
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _deleteAction() {
    return GridBottomSheetAction(Icons.delete, (selected) {
      _deleteDialog(context, selected);
    },
        false,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.deleteFilesActionLabel,
          body: AppLocalizations.of(context)!.deleteFilesActionBody,
        ));
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _copyAction() {
    return GridBottomSheetAction(Icons.copy, (selected) {
      _moveOrCopy(context, selected, false);
    },
        false,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.copyActionLabel,
          body: AppLocalizations.of(context)!.copyActionBody,
        ));
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _moveAction() {
    return GridBottomSheetAction(Icons.forward, (selected) {
      _moveOrCopy(context, selected, true);
    },
        false,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.moveActionLabel,
          body: AppLocalizations.of(context)!.moveActionBody,
        ));
  }

  GridBottomSheetAction<SystemGalleryDirectoryFile> _chooseAction() {
    return GridBottomSheetAction(Icons.check, (selected) {
      widget.callback!(selected.first);
    },
        false,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.chooseActionLabel,
          body: AppLocalizations.of(context)!.chooseActionBody,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<SystemGalleryDirectoryFile>(
      context,
      state,
      CallbackGrid(
          key: state.gridKey,
          getCell: (i) => widget.api.directCell(i),
          initalScrollPosition: 0,
          scaffoldKey: state.scaffoldKey,
          systemNavigationInsets: insets,
          hasReachedEnd: () => true,
          immutable: false,
          tightMode: true,
          addIconsImage: (cell) {
            return widget.callback != null
                ? [
                    _chooseAction(),
                  ]
                : extra.isTrash()
                    ? [
                        _restoreFromTrash(),
                      ]
                    : [
                        _addToFavoritesAction(),
                        _deleteAction(),
                        _copyAction(),
                        _moveAction()
                      ];
          },
          aspectRatio: state.settings.gallerySettings.filesAspectRatio.value,
          hideAlias: state.settings.gallerySettings.hideFileName,
          searchWidget: SearchAndFocus(
              searchWidget(context, hint: widget.dirName), searchFocus),
          mainFocus: state.mainFocus,
          hideShowFab: ({required bool fab, required bool foreground}) =>
              state.updateFab(setState, fab: fab, foreground: foreground),
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

                    final upTo = state
                        .gridKey.currentState?.mutationInterface?.cellCount;
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
                  },
                  icon: const Icon(Icons.casino_outlined)),
            IconButton(
                onPressed: () {
                  final settings = Settings.fromDb();
                  Settings.saveToDb(settings.copy(
                      gallerySettings: settings.gallerySettings.copy(
                          hideFileName:
                              !(settings.gallerySettings.hideFileName))));
                },
                icon: const Icon(Icons.subtitles))
          ],
          inlineMenuButtonItems: true,
          onBack: () {
            if (currentFilteringMode() != FilteringMode.noFilter) {
              resetSearch();
              return;
            }
            Navigator.pop(context);
          },
          progressTicker: stream.stream,
          description: GridDescription(
              kGalleryDrawerIndex,
              widget.callback != null
                  ? []
                  : extra.isTrash()
                      ? [
                          _restoreFromTrash(),
                        ]
                      : [
                          _bulkRename(),
                          _saveTagsAction(),
                          _addToFavoritesAction(),
                          _deleteAction(),
                          _copyAction(),
                          _moveAction(),
                        ],
              state.settings.gallerySettings.filesColumns,
              listView: state.settings.gallerySettings.filesListView,
              bottomWidget: widget.callback != null
                  ? copyMoveHintText(
                      context, AppLocalizations.of(context)!.chooseFileNotice)
                  : null,
              keybindsDescription: widget.dirName)),
      noDrawer: widget.callback != null,
      overrideOnPop: () {
        if (currentFilteringMode() != FilteringMode.noFilter) {
          resetSearch();
          return Future.value(false);
        }

        return Future.value(true);
      },
    );
  }
}

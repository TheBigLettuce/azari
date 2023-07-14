// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/gallery/android_api/android_directories.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import '../../schemas/settings.dart';
import '../../widgets/search_filter_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AndroidFiles extends StatefulWidget {
  final String dirName;
  final String bucketId;
  final GalleryAPIFilesRead<AndroidGalleryFilesExtra,
      SystemGalleryDirectoryFile, SystemGalleryDirectoryFileShrinked> api;
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
    with
        SearchFilterGrid<SystemGalleryDirectoryFile,
            SystemGalleryDirectoryFileShrinked> {
  late StreamSubscription<Settings?> settingsWatcher;
  late final extra = widget.api.getExtra()
    ..setOnThumbnailCallback(() {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        state.gridKey.currentState?.setState(() {});
      });
    })
    ..setRefreshingStatusCallback((i, inRefresh, empty) {
      if (empty) {
        state.gridKey.currentState?.currentBottomSheet?.close();
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
    ..setPassFilter((cells) {
      return switch (currentFilteringMode()) {
        FilteringMode.noFilter => cells,
        FilteringMode.video => _filterVideo(cells),
        FilteringMode.gif => _filterGif(cells),
        FilteringMode.duplicate => _filterDuplicate(cells),
        FilteringMode.original => _filterOriginal(cells)
      };
    });

  List<SystemGalleryDirectoryFile> _filterVideo(
      List<SystemGalleryDirectoryFile> cells) {
    return cells.where((element) => element.isVideo).toList();
  }

  List<SystemGalleryDirectoryFile> _filterGif(
      List<SystemGalleryDirectoryFile> cells) {
    return cells.where((element) => element.isGif).toList();
  }

  List<SystemGalleryDirectoryFile> _filterDuplicate(
      List<SystemGalleryDirectoryFile> cells) {
    return cells.where((element) => element.isDuplicate()).toList();
  }

  List<SystemGalleryDirectoryFile> _filterOriginal(
      List<SystemGalleryDirectoryFile> cells) {
    return cells
        .where((element) => PostTags().containsTag(element.name, "original"))
        .toList();
  }

  late final GridSkeletonStateFilter<
          SystemGalleryDirectoryFile, SystemGalleryDirectoryFileShrinked>
      state = GridSkeletonStateFilter(
          filter: extra.filter,
          index: kGalleryDrawerIndex,
          filteringModes: {
            FilteringMode.noFilter,
            FilteringMode.original,
            FilteringMode.duplicate,
            FilteringMode.gif,
            FilteringMode.video
          },
          onWillPop: () => Future.value(true));
  final stream = StreamController<int>(sync: true);

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
      List<SystemGalleryDirectoryFileShrinked> selected, bool move) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return AndroidDirectories(
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
            PlatformFunctions.copyMoveFiles(chosen, selected,
                move: move, newDir: newDir);
          }),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<SystemGalleryDirectoryFile,
            SystemGalleryDirectoryFileShrinked>(
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
            addIconsImage: (state) {
              return [
                IconButton(
                    onPressed: () {
                      deleteDialog(context, [state.currentCell.shrinkedData()]);
                    },
                    icon: const Icon(Icons.delete)),
                IconButton(
                    onPressed: () {
                      _moveOrCopy(
                          context, [state.currentCell.shrinkedData()], false);
                    },
                    icon: const Icon(Icons.copy)),
                IconButton(
                    onPressed: () {
                      _moveOrCopy(
                          context, [state.currentCell.shrinkedData()], true);
                    },
                    icon: const Icon(Icons.forward))
              ];
            },
            aspectRatio:
                state.settings.gallerySettings.filesAspectRatio?.value ?? 1,
            hideAlias: state.settings.gallerySettings.hideFileName,
            loadThumbsDirectly: extra.loadThumbnails,
            searchWidget: SearchAndFocus(
                searchWidget(context, hint: widget.dirName), searchFocus),
            mainFocus: state.mainFocus,
            hideShowFab: ({required bool fab, required bool foreground}) =>
                state.updateFab(setState, fab: fab, foreground: foreground),
            refresh: () {
              _refresh();
              return null;
            },
            menuButtonItems: [
              IconButton(
                  onPressed: () {
                    var settings = settingsIsar().settings.getSync(0)!;
                    settingsIsar().writeTxnSync(() => settingsIsar()
                        .settings
                        .putSync(settings.copy(
                            gallerySettings: settings.gallerySettings.copy(
                                hideFileName:
                                    !(settings.gallerySettings.hideFileName ??
                                        false)))));
                  },
                  icon: const Icon(Icons.subtitles))
            ],
            onBack: () {
              Navigator.pop(context);
            },
            progressTicker: stream.stream,
            overrideOnPress: widget.callback != null
                ? (context, indx) {
                    widget.callback?.call(state
                        .gridKey.currentState!.mutationInterface!
                        .getCell(indx)
                        .shrinkedData());
                  }
                : null,
            description: GridDescription(
                kGalleryDrawerIndex,
                widget.callback != null
                    ? []
                    : [
                        GridBottomSheetAction(Icons.delete, (selected) {
                          deleteDialog(context, selected);
                        }, false),
                        GridBottomSheetAction(Icons.copy, (selected) {
                          _moveOrCopy(context, selected, false);
                        }, false),
                        GridBottomSheetAction(Icons.forward, (selected) {
                          _moveOrCopy(context, selected, true);
                        }, false)
                      ],
                state.settings.gallerySettings.filesColumns ?? GridColumn.two,
                listView: state.settings.listViewBooru,
                bottomWidget: widget.callback != null
                    ? gridBottomWidgetText(
                        context, AppLocalizations.of(context)!.chooseFileNotice)
                    : null,
                keybindsDescription: widget.dirName)),
        noDrawer: widget.callback != null);
  }
}

void deleteDialog(
    BuildContext context, List<SystemGalleryDirectoryFileShrinked> selected) {
  Navigator.push(
      context,
      DialogRoute(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
                "${AppLocalizations.of(context)!.tagDeleteDialogTitle} ${selected.length} ${selected.length == 1 ? AppLocalizations.of(context)!.itemSingular : AppLocalizations.of(context)!.itemPlural}?"),
            content: Text(
              AppLocalizations.of(context)!.cannotBeReversed,
              style: const TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    PlatformFunctions.deleteFiles(selected);
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

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/gallery/android_api/android_directories.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import '../../schemas/settings.dart';
import '../../widgets/search_filter_grid.dart';

class AndroidFiles extends StatefulWidget {
  final String dirName;
  final String bucketId;
  final GalleryAPIFilesRead<AndroidGalleryFilesExtra,
      SystemGalleryDirectoryFile, SystemGalleryDirectoryFileShrinked> api;
  const AndroidFiles(
      {super.key,
      required this.api,
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
      setState(() {});
    })
    ..setRefreshingStatusCallback((i, inRefresh, empty) {
      if (empty) {
        Navigator.of(context).pop();
        return;
      }

      state.gridKey.currentState?.mutationInterface?.unselectAll();

      if (!inRefresh) {
        state.gridKey.currentState?.mutationInterface?.setIsRefreshing(false);
        setState(() {});
      }

      stream.add(i);
    })
    ..setRefreshGridCallback(_refresh);

  late final GridSkeletonStateFilter<SystemGalleryDirectoryFile,
          SystemGalleryDirectoryFileShrinked> state =
      GridSkeletonStateFilter(
          filter: extra.filter,
          index: kGalleryDrawerIndex,
          onWillPop: () => Future.value(true));
  final stream = StreamController<int>(sync: true);

  @override
  void initState() {
    super.initState();

    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      state.settings = event!;

      setState(() {});
    });
    searchHook(state, [
      IconButton(
          onPressed: () {
            var settings = settingsIsar().settings.getSync(0)!;
            settingsIsar().writeTxnSync(() => settingsIsar().settings.putSync(
                settings.copy(
                    gallerySettings: settings.gallerySettings.copy(
                        hideFileName: !(settings.gallerySettings.hideFileName ??
                            false)))));
          },
          icon: const Icon(Icons.subtitles))
    ]);
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
          callback: CallbackDescription(move ? "move" : "copy", (chosen) {
            // TODO: change
            if (chosen.bucketId == widget.bucketId) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(move
                      ? "Can't move to same destination"
                      : "Can't copy to same destination"))); // TODO: change
              return;
            }
            const MethodChannel channel =
                MethodChannel("lol.bruh19.azari.gallery");
            channel.invokeMethod("copyMoveFiles", {
              "dest": chosen.relativeLoc,
              "media": selected.map((e) => e.id).toList(),
              "move": move
            });
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
            onBack: () {
              Navigator.pop(context);
            },
            progressTicker: stream.stream,
            description: GridDescription(
                kGalleryDrawerIndex,
                [
                  GridBottomSheetAction(Icons.delete, (selected) {
                    Navigator.push(
                        context,
                        DialogRoute(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                  "Do you want to delete ${selected.length} ${selected.length == 1 ? 'item' : 'items'}?"), // TODO: change
                              content: const Text(
                                "This cannot be reversed",
                                style: TextStyle(
                                    color: Colors.red), // TODO: change
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      const MethodChannel channel =
                                          MethodChannel(
                                              "lol.bruh19.azari.gallery");
                                      channel.invokeMethod(
                                          "deleteFiles",
                                          selected
                                              .map((e) => e.originalUri)
                                              .toList());
                                      Navigator.pop(context);
                                    },
                                    child: Text("yes")),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text("no"))
                              ],
                            );
                          },
                        ));
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
                keybindsDescription: widget.dirName)));
  }
}

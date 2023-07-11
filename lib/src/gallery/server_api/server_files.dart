// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/gallery/server_api/server_api_directories.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../db/isar.dart' as db;
import '../../widgets/search_filter_grid.dart';

class Images extends StatefulWidget {
  final Directory cell;
  final GalleryAPIFilesReadWrite<ServerApiFilesExtra, DirectoryFile,
      DirectoryFileShrinked> api;
  final GlobalKey<CallbackGridState> parentGrid;
  final void Function(String hash, Directory d) setThumbnail;
  final FocusNode parentFocus;
  const Images(this.api,
      {super.key,
      required this.cell,
      required this.parentFocus,
      required this.setThumbnail,
      required this.parentGrid});

  @override
  State<Images> createState() => _ImagesState();
}

class _ImagesState extends State<Images>
    with SearchFilterGrid<DirectoryFile, DirectoryFileShrinked> {
  late StreamSubscription<Settings?> settingsWatcher;
  bool isDisposed = false;

  late final GridSkeletonStateFilter<DirectoryFile, DirectoryFileShrinked>
      skeletonState = GridSkeletonStateFilter(
    filter: widget.api.getExtra().filter,
    index: kGalleryDrawerIndex,
    onWillPop: () => Future.value(true),
  );

  @override
  void initState() {
    super.initState();

    searchHook(skeletonState);

    settingsWatcher = db.settingsIsar().settings.watchObject(0).listen((event) {
      skeletonState.settings = event!;

      setState(() {});
    });
  }

  void _addFiles() async {
    try {
      var res = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.media,
          allowCompression: false,
          withReadStream: true,
          lockParentWindow: true);

      if (res == null || res.count == 0) {
        throw "empty files";
      }

      await widget.api.uploadFiles(res.files, () {
        if (!isDisposed) {
          skeletonState.gridKey.currentState?.refresh();
          widget.parentGrid.currentState?.refresh();
        }
      });
    } catch (e, trace) {
      log("picking files",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  void _deleteFiles(List<DirectoryFileShrinked> f) {
    widget.api.deleteFiles(f, () {
      skeletonState.gridKey.currentState?.refresh();
      widget.parentGrid.currentState?.refresh();
    }).onError((error, stackTrace) {
      log("deleting files",
          level: Level.SEVERE.value, error: error, stackTrace: stackTrace);
    });
  }

  @override
  void dispose() {
    isDisposed = true;
    disposeSearch();
    settingsWatcher.cancel();
    skeletonState.dispose();
    widget.api.close();
    super.dispose();
  }

  Future<void> _download(int indx) {
    var df = widget.api.directCell(indx);

    Downloader().add(File.d(df.fileDownloadUrl(), "gallery", df.name));

    return Future.value();
  }

  void _setFolderThumbnail(String thumbHash) {
    widget.setThumbnail(thumbHash, widget.cell);
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton<DirectoryFile, DirectoryFileShrinked>(
      context,
      skeletonState,
      CallbackGrid(
          mainFocus: skeletonState.mainFocus,
          systemNavigationInsets: insets,
          key: skeletonState.gridKey,
          aspectRatio:
              skeletonState.settings.gallerySettings.filesAspectRatio?.value ??
                  1,
          description: GridDescription(
              kGalleryDrawerIndex,
              [
                GridBottomSheetAction(
                  Icons.delete,
                  (selected) {
                    Navigator.of(context).push(DialogRoute(
                        context: context,
                        builder: ((context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!
                                .deleteImageConfirm),
                            content: Text(
                                "${selected.length} ${selected.length > 1 ? AppLocalizations.of(context)!.itemSingular : AppLocalizations.of(context)!.itemPlural}"),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.no)),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);

                                    _deleteFiles(selected);
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.yes)),
                            ],
                          );
                        })));
                  },
                  true,
                ),
                GridBottomSheetAction(Icons.info_outline, (selected) {
                  var df = selected.first;

                  Navigator.of(context).push(DialogRoute(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: ListTile(
                            title: Text(
                                AppLocalizations.of(context)!.setAsThumbnail),
                            onTap: () {
                              Navigator.pop(context);
                              _setFolderThumbnail(df.thumbHash);
                            },
                          ),
                        );
                      }));
                }, false, showOnlyWhenSingle: true)
              ],
              skeletonState.settings.gallerySettings.filesColumns ??
                  GridColumn.two,
              keybindsDescription:
                  AppLocalizations.of(context)!.galleryInnerPageName,
              pageName: widget.cell.dirName,
              listView: skeletonState.settings.listViewBooru),
          scaffoldKey: skeletonState.scaffoldKey,
          refresh: widget.api.refresh,
          tightMode: true,
          hideAlias: skeletonState.settings.gallerySettings.hideFileName,
          menuButtonItems: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  _addFiles();

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.uploadStarted)));
                },
                child: Text(AppLocalizations.of(context)!.addFiles))
          ],
          hasReachedEnd: () => true,
          searchWidget: SearchAndFocus(searchWidget(context), searchFocus),
          download: _download,
          onBack: () => Navigator.of(context).pop(),
          immutable: false,
          // loadNext: () => _loadNext(),
          getCell: (i) => widget.api.directCell(i),
          initalScrollPosition: 0,
          belowMainFocus: widget.parentFocus,
          hideShowFab: ({required bool fab, required bool foreground}) =>
              skeletonState.updateFab(setState,
                  fab: fab, foreground: foreground)),
    );
  }
}

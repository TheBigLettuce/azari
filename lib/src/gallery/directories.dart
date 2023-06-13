// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/gallery/images.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/gallery/modify_directory.dart';
import 'package:gallery/src/gallery/server_api/server.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';
import '../db/isar.dart' as db;
import '../widgets/drawer/drawer.dart';
import '../widgets/grid/callback_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Directories extends StatefulWidget {
  const Directories({super.key});

  @override
  State<Directories> createState() => _DirectoriesState();
}

class _DirectoriesState extends State<Directories> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final GlobalKey<CallbackGridState> _gridKey = GlobalKey();
  // late final Isar isar;
  //late Stream<int> thumbnailWatcher;
  late Settings settings = db.isar().settings.getSync(0)!;
  late StreamSubscription<Settings?> settingsWatcher;
  GalleryAPI<DirectoryFileShrinked> api = ServerAPI(db.openServerApiIsar());
  Result<Directory>? directories;
  bool isDisposed = false;

  FocusNode mainFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    settingsWatcher = db.isar().settings.watchObject(0).listen((event) {
      setState(() {
        settings = event!;
      });
    });
  }

  Future<int> _refresh(
    bool sets,
  ) async {
    try {
      var d = await api.directories();

      if (sets) {
        if (!isDisposed) {
          setState(() {
            directories = d;
          });
        }
      } else {
        directories = d;
      }
    } catch (e, trace) {
      log("refreshing directories",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }

    return directories == null
        ? 0
        : directories!.count; //isar.directorys.count();
  }

  @override
  void dispose() {
    isDisposed = true;

    settingsWatcher.cancel();
    //db.closeDirectoryIsar();

    mainFocus.dispose();
    api.close();

    super.dispose();
  }

  void _setThumbnail(String hash, Directory d) async {
    try {
      await api.setThumbnail(hash, d);

      _gridKey.currentState!.refresh();
    } catch (e, trace) {
      log("setting thumbnail",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton(
        context,
        kGalleryDrawerIndex,
        () => popUntilSenitel(context),
        _key,
        CallbackGrid<Directory, Directory>(
          systemNavigationInsets: insets,
          key: _gridKey,
          columns: settings.gallerySettings.directoryColumns ?? GridColumn.two,
          aspectRatio:
              settings.gallerySettings.directoryAspectRatio?.value ?? 1,
          description: GridDescription(
            kGalleryDrawerIndex,
            AppLocalizations.of(context)!.galleryPageName,
            [
              GridBottomSheetAction(Icons.info_outline, (selected) {
                var d = selected.first;

                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ModifyDirectory(
                    api,
                    old: d,
                    refreshKey: _gridKey,
                  );
                }));
              }, false, showOnlyWhenSingle: true)
            ],
          ),
          updateScrollPosition: (pos, {double? infoPos, int? selectedCell}) {},
          scaffoldKey: _key,
          //progressTicker: thumbnailWatcher,
          hasReachedEnd: () => true,
          refresh: () => _refresh(false),
          search: (s) {},
          hideAlias: settings.gallerySettings.hideDirectoryName,
          initalScrollPosition: 0,
          menuButtonItems: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      DialogRoute(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(AppLocalizations.of(context)!
                                  .chooseDirectoryName),
                              content: TextField(
                                onSubmitted: (value) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              AppLocalizations.of(context)!
                                                  .uploadStarted)));
                                  api.newDirectory(value, () {
                                    if (!isDisposed) {
                                      _gridKey.currentState?.refresh();
                                    }
                                  }).then((value) {
                                    _refresh(true);
                                    _gridKey.currentState!.refresh();
                                  }).onError((error, stackTrace) {
                                    log("adding file to server",
                                        level: Level.SEVERE.value,
                                        error: error,
                                        stackTrace: stackTrace);
                                  });
                                },
                              ),
                            );
                          }));
                },
                child: Text(AppLocalizations.of(context)!.newDirectory))
          ],
          getCell: (i) =>
              directories!.cell(i), //isar.directorys.getSync(i + 1)!.cell()
          overrideOnPress: (context, indx) {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              var d = directories!.cell(indx);

              return Images(
                api.images(d),
                cell: d,
                setThumbnail: _setThumbnail,
                parentGrid: _gridKey,
              );
            }));
          },
        ));
  }
}

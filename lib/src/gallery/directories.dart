// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/gallery/images.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/gallery/server_api/server.dart';
import 'package:gallery/src/pages/senitel.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';
import '../db/isar.dart' as db;
import '../widgets/drawer/drawer.dart';
import '../widgets/grid/callback_grid.dart';

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
  GalleryAPI api = ServerAPI(db.openServerApiIsar());
  Result<Directory>? directories;
  bool isDisposed = false;

  FocusNode mainFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // isar = db.openDirectoryIsar();

    // thumbnailWatcher = isar.directorys
    //     .watchLazy()
    //     .transform(StreamTransformer((stream, cancelOnError) {
    //   var c = StreamController<int>(sync: true);
    //   c.onListen = () {
    //     var subscription = stream.listen(
    //       (event) {
    //         c.add(isar.directorys.countSync());
    //       },
    //       onError: c.addError,
    //       onDone: c.close,
    //       cancelOnError: cancelOnError,
    //     );

    //     c.onPause = subscription.pause;
    //     c.onResume = subscription.resume;
    //     c.onCancel = subscription.cancel;
    //   };

    //   return c.stream.listen(null);
    // }));

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

    /*try {
      await PhotoManager.getAssetPathList(
        hasAll: false,
      ).then((value) async {
        isar.writeTxnSync(() => isar.directorys.clearSync());

        for (var directory in value) {
          var asset = await directory.getAssetListRange(end: 1, start: 0);
          if (asset.isEmpty) {
            throw "is empty";
          }

          try {
            var thumb = await asset.first.thumbnailData;

            var lastModified = (await directory.fetchPathProperties(
                    filterOptionGroup:
                        FilterOptionGroup(containsPathModified: true)))!
                .lastModified!;

            isar.writeTxnSync(() => isar.directorys.putByIdSync(
                Directory(directory.id, directory.name, thumb!, lastModified)));
          } catch (e) {
            print("while gettinh thumb: $e");
          }
        }
      });
    } catch (e) {
      print(e);
    }*/

    return directories == null
        ? 0
        : directories!.count; //isar.directorys.count();
  }

  void _delete(Directory d) async {
    try {
      await api.delete(d);

      _gridKey.currentState!.refresh();
    } catch (e, trace) {
      log("deleting directory",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
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

  @override
  Widget build(BuildContext context) {
    return makeGridSkeleton(
        context,
        kGalleryDrawerIndex,
        () => popUntilSenitel(context),
        GlobalKey(),
        CallbackGrid<Directory>(
          key: _gridKey,
          description: const GridDescription(
            kGalleryDrawerIndex,
            "Gallery",
          ),
          updateScrollPosition: (pos, {double? infoPos, int? selectedCell}) {},
          scaffoldKey: _key,
          //progressTicker: thumbnailWatcher,
          hasReachedEnd: () => true,
          refresh: () => _refresh(false),
          search: (s) {},
          onLongPress: (indx) {
            var d = directories!.cell(indx);

            Navigator.push(
                context,
                DialogRoute(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Do you want to delete: ${d.dirName}"),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("no")),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _delete(d);
                              },
                              child: Text("yes")),
                        ],
                      );
                    }));

            return Future.value();
          },
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
                              title: Text("Choose name"),
                              content: TextField(
                                onSubmitted: (value) {
                                  Navigator.pop(context);
                                  api.newDirectory(value).then((value) {
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
                child: Text("New directory"))
          ],
          getCell: (i) =>
              directories!.cell(i), //isar.directorys.getSync(i + 1)!.cell()
          overrideOnPress: (context, indx) {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              var d = directories!.cell(indx);

              return Images(
                api.images(d),
                cell: d,
              );
            }));
          },
        ));
  }
}

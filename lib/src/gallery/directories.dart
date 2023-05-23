// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/cell/directory.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:isar/isar.dart';
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
  late final Isar isar;
  late Stream<int> thumbnailWatcher;
  late Settings settings = db.isar().settings.getSync(0)!;
  late StreamSubscription<Settings?> settingsWatcher;

  @override
  void initState() {
    super.initState();

    isar = db.openDirectoryIsar();

    thumbnailWatcher = isar.directorys
        .watchLazy()
        .transform(StreamTransformer((stream, cancelOnError) {
      var c = StreamController<int>(sync: true);
      c.onListen = () {
        var subscription = stream.listen(
          (event) {
            c.add(isar.directorys.countSync());
          },
          onError: c.addError,
          onDone: c.close,
          cancelOnError: cancelOnError,
        );

        c.onPause = subscription.pause;
        c.onResume = subscription.resume;
        c.onCancel = subscription.cancel;
      };

      return c.stream.listen(null);
    }));

    settingsWatcher = db.isar().settings.watchObject(0).listen((event) {
      setState(() {
        settings = event!;
      });
    });
  }

  Future<int> _refresh() async {
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

    return isar.directorys.count();
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    db.closeDirectoryIsar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future.value(true);
      },
      child: Scaffold(
          key: _key,
          drawer: makeDrawer(context, -1),
          body: CallbackGrid<DirectoryCell>(
            updateScrollPosition: (pos,
                {double? infoPos, int? selectedCell}) {},
            scaffoldKey: _key,
            progressTicker: thumbnailWatcher,
            hasReachedEnd: () => true,
            refresh: _refresh,
            search: (s) {},
            initalCellCount: isar.directorys.countSync(),
            initalScrollPosition: 0,
            getCell: (i) => isar.directorys.getSync(i + 1)!.cell(),
            overrideOnPress: (context, indx) {
              //  Navigator.push(context, MaterialPageRoute(builder: (context) {
              //   return Images(cell: isar.directorys.getSync(indx + 1)!.cell());
              // }));
            },
          )),
    );
  }
}

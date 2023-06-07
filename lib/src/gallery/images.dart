// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:logging/logging.dart';

class Images extends StatefulWidget {
  final Directory cell;
  final GalleryAPIFiles api;
  const Images(this.api, {super.key, required this.cell});

  @override
  State<Images> createState() => _ImagesState();
}

class _ImagesState extends State<Images> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final GlobalKey<CallbackGridState> _gridKey = GlobalKey();
  Result<DirectoryFile>? cells;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
  }

  void _addFiles() async {
    try {
      var res = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.image,
          allowCompression: false,
          withReadStream: true,
          lockParentWindow: true);

      if (res == null || res.count == 0) {
        throw "empty files";
      }

      await widget.api.uploadFiles(res.files);

      _gridKey.currentState!.refresh();
    } catch (e, trace) {
      log("picking files",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  Future<int> _refresh() async {
    return _loadNext(true);
  }

  Future<int> _loadNext(bool refresh) async {
    try {
      if (refresh) {
        cells = await widget.api.refresh();
      } else {
        cells = await widget.api.nextImages();
      }
    } catch (e, stackTrace) {
      log("load next images in gallery images",
          level: Level.WARNING.value, error: e, stackTrace: stackTrace);
    }

    return cells == null ? 0 : cells!.count;
  }

  void _deleteFile(DirectoryFile f) async {
    try {
      await widget.api.delete(f);

      await _refresh();
    } catch (e, trace) {
      log("deleting file",
          level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    widget.api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeGridSkeleton(
        context,
        kGalleryDrawerIndex,
        () => Future.value(true),
        _key,
        CallbackGrid<DirectoryFile>(
          key: _gridKey,
          description:
              GridDescription(kGalleryDrawerIndex, "Inner directory grid"),
          updateScrollPosition: (pos, {double? infoPos, int? selectedCell}) {},
          scaffoldKey: _key,
          refresh: _refresh,
          menuButtonItems: [
            TextButton(
                onPressed: () {
                  _addFiles();

                  Navigator.pop(context);
                },
                child: Text("Add files"))
          ],
          hasReachedEnd: () => widget.api.reachedEnd,
          search: (s) {},
          onBack: () => Navigator.of(context).pop(),
          loadNext: () => _loadNext(false),
          getCell: (i) => cells!.cell(i),
          initalScrollPosition: 0,
          onLongPress: (indx) {
            var df = cells!.cell(indx);

            return Navigator.of(context).push(DialogRoute(
                context: context,
                builder: ((context) {
                  return AlertDialog(
                    title: const Text("Do you want to delete:"),
                    content: Text(df.name),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("no")),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);

                            _deleteFile(df);
                          },
                          child: const Text("yes")),
                    ],
                  );
                })));
          },
        ));
  }
}

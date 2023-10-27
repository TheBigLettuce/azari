// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:isar/isar.dart';

import '../../interfaces/cell.dart';
import '../../interfaces/contentable.dart';
import '../../pages/image_view.dart';
import '../../plugs/platform_channel.dart';
import '../../widgets/grid/cell_data.dart';
import 'note.dart';
import 'system_gallery_directory_file.dart';

part 'note_gallery.g.dart';

@collection
class NoteGallery extends NoteBase implements Cell {
  @override
  Id? isarId;

  @Index(unique: true, replace: true)
  final int id;
  final String originalUri;

  final int height;
  final int width;

  final bool isVideo;
  final bool isGif;

  static bool add(int id,
      {required List<String> text,
      required int height,
      required int width,
      required bool isVideo,
      required bool isGif,
      required String originalUri}) {
    final n = Dbs.g.main.noteGallerys.getByIdSync(id);

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.noteGallerys.putByIdSync(
        NoteGallery([...n?.text ?? [], ...text], DateTime.now(),
            id: id,
            originalUri: originalUri,
            height: height,
            width: width,
            isGif: isGif,
            isVideo: isVideo)));

    return n == null;
  }

  static bool hasNotes(int id) {
    return Dbs.g.main.noteGallerys.getByIdSync(id) != null;
  }

  static bool removeAll(int id) {
    return Dbs.g.main
        .writeTxnSync(() => Dbs.g.main.noteGallerys.deleteByIdSync(id));
  }

  static bool remove(int id, int indx) {
    final n = Dbs.g.main.noteGallerys.getByIdSync(id);
    if (n == null) {
      return false;
    }

    final newText = n.text.toList()..removeAt(indx);

    return Dbs.g.main.writeTxnSync(() {
      if (newText.isEmpty) {
        Dbs.g.main.noteGallerys.deleteByIdSync(id);
        return true;
      } else {
        Dbs.g.main.noteGallerys.putByIdSync(NoteGallery(newText, n.time,
            id: id,
            originalUri: n.originalUri,
            height: n.height,
            width: n.width,
            isGif: n.isGif,
            isVideo: n.isVideo));
        return false;
      }
    });
  }

  static void replace(int id, int tidx, String newText) {
    final n = Dbs.g.main.noteGallerys.getByIdSync(id);
    if (n == null) {
      return;
    }

    final t = n.text.toList();
    t[tidx] = newText;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.noteGallerys.putByIdSync(
        NoteGallery(t, n.time,
            id: n.id,
            originalUri: n.originalUri,
            height: n.height,
            width: n.width,
            isGif: n.isGif,
            isVideo: n.isVideo)));
  }

  static NoteInterface<NoteGallery> interfaceSelf(
      void Function(void Function()) setState) {
    return NoteInterface(
      addNote: (text, cell) {
        NoteGallery.add(cell.id,
            text: [text],
            height: cell.height,
            width: cell.width,
            isVideo: cell.isVideo,
            isGif: cell.isGif,
            originalUri: cell.originalUri);
      },
      delete: (cell, indx) {
        NoteGallery.remove(cell.id, indx);
      },
      load: (cell) {
        return Dbs.g.main.noteGallerys.getByIdSync(cell.id);
      },
      replace: (cell, indx, newText) {
        NoteGallery.replace(cell.id, indx, newText);
      },
    );
  }

  static NoteInterface<SystemGalleryDirectoryFile> interface(
      void Function({int? replaceIndx, bool addNote, int? removeNote})
          refresh) {
    return NoteInterface(
      addNote: (text, cell) {
        NoteGallery.add(cell.id,
            text: [text],
            height: cell.height,
            width: cell.width,
            isVideo: cell.isVideo,
            isGif: cell.isGif,
            originalUri: cell.originalUri);

        refresh(addNote: true);
      },
      delete: (cell, indx) {
        NoteGallery.remove(cell.id, indx);
        refresh(removeNote: indx);
      },
      load: (cell) {
        return Dbs.g.main.noteGallerys.getByIdSync(cell.id);
      },
      replace: (cell, indx, newText) {
        NoteGallery.replace(cell.id, indx, newText);
        refresh(removeNote: indx);
      },
    );
  }

  static List<NoteGallery> load() {
    return Dbs.g.main.noteGallerys.where().findAllSync();
  }

  NoteGallery(super.text, super.time,
      {required this.id,
      required this.originalUri,
      required this.height,
      required this.width,
      required this.isGif,
      required this.isVideo});

  @override
  List<Widget>? addButtons(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            PlatformFunctions.shareMedia(originalUri);
          },
          icon: const Icon(Icons.share))
    ];
  }

  @override
  List<Widget>? addInfo(BuildContext context, extra, AddInfoColorData colors) {
    return null;
  }

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) {
    return null;
  }

  @override
  String alias(bool isList) {
    return id.toString();
  }

  @override
  Contentable fileDisplay() {
    final size = Size(width.toDouble(), height.toDouble());

    if (isVideo) {
      return AndroidVideo(uri: originalUri, size: size);
    }

    if (isGif) {
      return AndroidGif(uri: originalUri, size: size);
    }

    return AndroidImage(uri: originalUri, size: size);
  }

  @override
  String fileDownloadUrl() {
    return "";
  }

  @override
  CellData getCellData(bool isList, {required BuildContext context}) {
    return CellData(
        thumb: ThumbnailProvider(id, isVideo ? id.toString() : null),
        name: id.toString(),
        stickers: const []);
  }
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/note_base.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart';
import 'package:gallery/src/interfaces/note_interface.dart';
import 'package:isar/isar.dart';

part 'note_gallery.g.dart';

@collection
class NoteGallery extends NoteBase {
  NoteGallery(
    super.text,
    super.time, {
    required this.id,
    required this.originalUri,
    required this.height,
    required this.width,
    required super.backgroundColor,
    required super.textColor,
    required this.isGif,
    required this.isVideo,
  });

  // @override
  // Contentable content() {
  //   final size = Size(width.toDouble(), height.toDouble());

  //   if (isVideo) {
  //     return AndroidVideo(uri: originalUri, size: size);
  //   }

  //   if (isGif) {
  //     return AndroidGif(uri: originalUri, size: size);
  //   }

  //   return AndroidImage(uri: originalUri, size: size);
  // }

  // @override
  // ImageProvider<Object>? thumbnail() =>
  //     SystemGalleryThumbnailProvider(id, isVideo);

  //       @override
  // List<Widget>? addButtons(BuildContext context) {
  //   return [
  //     IconButton(
  //         onPressed: () {
  //           PlatformFunctions.shareMedia(originalUri);
  //         },
  //         icon: const Icon(Icons.share))
  //   ];
  // }

  @override
  Key uniqueKey() => ValueKey(id);

  @Index(unique: true, replace: true)
  final int id;
  final String originalUri;

  final int height;
  final int width;

  final bool isVideo;
  final bool isGif;

  static void reorder({required int id, required int from, required int to}) {}

  static bool add(int id,
      {required List<String> text,
      required int height,
      required int width,
      required bool isVideo,
      required bool isGif,
      required Color? backgroundColor,
      required Color? textColor,
      required String originalUri}) {
    final n = Dbs.g.main.noteGallerys.getByIdSync(id);

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.noteGallerys.putByIdSync(
        NoteGallery([...n?.text ?? [], ...text], DateTime.now(),
            id: id,
            backgroundColor: backgroundColor?.value,
            textColor: textColor?.value,
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
            backgroundColor: n.backgroundColor,
            textColor: n.textColor,
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
            backgroundColor: n.backgroundColor,
            textColor: n.textColor,
            originalUri: n.originalUri,
            height: n.height,
            width: n.width,
            isGif: n.isGif,
            isVideo: n.isVideo)));
  }

  static NoteInterface<NoteGallery> interfaceSelf(void Function() onDelete) {
    return NoteInterface(
      reorder: (cell, from, to) {
        reorder(id: cell.id, from: from, to: to);
      },
      addNote: (text, cell, backgroundColor, textColor) {
        if (NoteGallery.add(cell.id,
            text: [text],
            height: cell.height,
            width: cell.width,
            backgroundColor: backgroundColor,
            textColor: textColor,
            isVideo: cell.isVideo,
            isGif: cell.isGif,
            originalUri: cell.originalUri)) {
          onDelete();
        }
      },
      delete: (cell, indx) {
        if (NoteGallery.remove(cell.id, indx)) {
          onDelete();
        }
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
      reorder: (cell, from, to) {
        reorder(id: cell.id, from: from, to: to);
      },
      addNote: (text, cell, backgroundColor, textColor) {
        NoteGallery.add(cell.id,
            text: [text],
            backgroundColor: backgroundColor,
            textColor: textColor,
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

  List<String> currentText() {
    if (isarId == null) {
      return const [];
    }

    return Dbs.g.main.noteGallerys.getByIdSync(id)!.text;
  }
}

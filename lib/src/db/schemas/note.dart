// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import 'package:gallery/src/db/schemas/tags.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path_util;
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/post.dart';
import 'package:gallery/src/interfaces/contentable.dart';
import 'package:gallery/src/pages/image_view.dart';
import 'package:gallery/src/widgets/grid/cell_data.dart';
import 'package:isar/isar.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../interfaces/booru.dart';
import '../../interfaces/cell.dart';
import 'settings.dart';

part 'note.g.dart';

@collection
class NoteBooru extends NoteBase implements Cell {
  @Index(unique: true, replace: true, composite: [CompositeIndex("booru")])
  final int postId;
  @enumerated
  final Booru booru;

  final String fileUrl;
  final String previewUrl;
  final String sampleUrl;

  static void add(int pid, Booru booru,
      {required String text,
      required String fileUrl,
      required String sampleUrl,
      required previewUrl}) {
    final n = Dbs.g.blacklisted.noteBoorus.getByPostIdBooruSync(pid, booru);

    Dbs.g.blacklisted.writeTxnSync(() => Dbs.g.blacklisted.noteBoorus
        .putByPostIdBooruSync(NoteBooru(
            [...n?.text ?? [], text], DateTime.now(),
            postId: pid,
            booru: booru,
            fileUrl: fileUrl,
            sampleUrl: sampleUrl,
            previewUrl: previewUrl)));
  }

  static void replace(int pid, Booru booru, int idx, String newText) {
    final n = Dbs.g.blacklisted.noteBoorus.getByPostIdBooruSync(pid, booru);
    if (n == null) {
      return;
    }
    final t = n.text.toList();
    t[idx] = newText;

    Dbs.g.blacklisted.writeTxnSync(() => Dbs.g.blacklisted.noteBoorus
        .putByPostIdBooruSync(NoteBooru(t, n.time,
            postId: n.postId,
            booru: n.booru,
            fileUrl: n.fileUrl,
            sampleUrl: n.sampleUrl,
            previewUrl: n.previewUrl)));
  }

  static void remove(int pid, Booru booru, int indx) {
    final n = Dbs.g.blacklisted.noteBoorus.getByPostIdBooruSync(pid, booru);
    if (n == null) {
      return;
    }
    final t = n.text.toList()..removeAt(indx);
    Dbs.g.blacklisted.writeTxnSync(() {
      if (t.isEmpty) {
        Dbs.g.blacklisted.noteBoorus.deleteByPostIdBooruSync(pid, booru);
      } else {
        Dbs.g.blacklisted.noteBoorus.putByPostIdBooruSync(NoteBooru(
            t, DateTime.now(),
            postId: pid,
            booru: booru,
            fileUrl: n.fileUrl,
            sampleUrl: n.sampleUrl,
            previewUrl: n.previewUrl));
      }
    });
  }

  static bool hasNotes(int pid, Booru booru) {
    return Dbs.g.blacklisted.noteBoorus.getByPostIdBooruSync(pid, booru) !=
        null;
  }

  static List<NoteBooru> load() {
    return Dbs.g.blacklisted.noteBoorus.where().findAllSync();
  }

  static NoteInterface<NoteBooru> interfaceSelf(
      void Function(void Function()) setState) {
    return NoteInterface(
      addNote: (text, cell) {
        NoteBooru.add(cell.postId, cell.booru,
            text: text,
            fileUrl: cell.fileUrl,
            sampleUrl: cell.sampleUrl,
            previewUrl: cell.previewUrl);
      },
      delete: (cell, indx) {
        NoteBooru.remove(cell.postId, cell.booru, indx);
      },
      load: (cell) {
        return Dbs.g.blacklisted.noteBoorus
            .getByPostIdBooruSync(cell.postId, cell.booru);
      },
      replace: (cell, indx, newText) {
        NoteBooru.replace(cell.postId, cell.booru, indx, newText);
      },
    );
  }

  static NoteInterface<T> interface<T extends PostBase>(
      void Function(void Function()) setState) {
    return NoteInterface(
      addNote: (text, cell) {
        NoteBooru.add(
          cell.id,
          Booru.fromPrefix(cell.prefix)!,
          text: text,
          fileUrl: cell.fileUrl,
          sampleUrl: cell.sampleUrl,
          previewUrl: cell.previewUrl,
        );
        setState(() {});
      },
      replace: (cell, indx, newText) {
        NoteBooru.replace(
            cell.id, Booru.fromPrefix(cell.prefix)!, indx, newText);
      },
      delete: (cell, indx) {
        NoteBooru.remove(cell.id, Booru.fromPrefix(cell.prefix)!, indx);
        setState(() {});
      },
      load: (cell) {
        return Dbs.g.blacklisted.noteBoorus
            .getByPostIdBooruSync(cell.id, Booru.fromPrefix(cell.prefix)!);
      },
    );
  }

  NoteBooru(super.text, super.time,
      {required this.postId,
      required this.booru,
      required this.fileUrl,
      required this.sampleUrl,
      required this.previewUrl});

  @override
  int? isarId;

  @override
  List<Widget>? addButtons(BuildContext context) {
    return null;
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
    return postId.toString();
  }

  @override
  Contentable fileDisplay() {
    String url = switch (Settings.fromDb().quality) {
      DisplayQuality.original => fileUrl,
      DisplayQuality.sample => sampleUrl
    };

    var type = lookupMimeType(url);
    if (type == null) {
      return const EmptyContent();
    }

    var typeHalf = type.split("/");

    if (typeHalf[0] == "image") {
      ImageProvider provider;
      try {
        provider = NetworkImage(url);
      } catch (e) {
        provider = MemoryImage(kTransparentImage);
      }

      return typeHalf[1] == "gif" ? NetGif(provider) : NetImage(provider);
    } else if (typeHalf[0] == "video") {
      return NetVideo(url);
    } else {
      return const EmptyContent();
    }
  }

  @override
  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  @override
  CellData getCellData(bool isList, {required BuildContext context}) {
    return CellData(
        thumb: CachedNetworkImageProvider(previewUrl),
        name: postId.toString(),
        stickers: const []);
  }
}

class NoteBase {
  Id? id;

  @Index(caseSensitive: false, type: IndexType.hash)
  final List<String> text;
  @Index()
  final DateTime time;

  NoteBase(this.text, this.time);
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/booru_post_functionality_mixin.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:path/path.dart' as path_util;
import 'package:isar/isar.dart';

import '../../base/note_base.dart';

part 'note_booru.g.dart';

@collection
class NoteBooru extends NoteBase
    with BooruPostFunctionalityMixin
    implements Thumbnailable, Downloadable {
  NoteBooru(
    super.text,
    super.time, {
    required this.postId,
    required this.booru,
    required super.backgroundColor,
    required super.textColor,
    required this.fileUrl,
    required this.sampleUrl,
    required this.previewUrl,
  });

  @Index(unique: true, replace: true, composite: [CompositeIndex("booru")])
  final int postId;
  @enumerated
  final Booru booru;

  final String fileUrl;
  final String previewUrl;
  final String sampleUrl;

  @override
  Key uniqueKey() => ValueKey((postId, booru));

  @override
  ImageProvider thumbnail() => CachedNetworkImageProvider(previewUrl);

  @override
  String alias(bool isList) => postId.toString();

  @override
  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  static void reorder(
      {required int postId,
      required Booru booru,
      required int from,
      required int to}) {
    final n = Dbs.g.blacklisted.noteBoorus.getByPostIdBooruSync(postId, booru);
    if (n == null || from == to) {
      return;
    }

    final newText = n.text.toList();
    final e1 = newText[from];
    newText.removeAt(from);
    if (to == 0) {
      newText.insert(0, e1);
    } else {
      newText.insert(to - 1, e1);
    }

    Dbs.g.blacklisted.writeTxnSync(() => Dbs.g.blacklisted.noteBoorus
        .putByPostIdBooruSync(NoteBooru(newText, n.time,
            postId: postId,
            booru: booru,
            backgroundColor: n.backgroundColor,
            textColor: n.textColor,
            fileUrl: n.fileUrl,
            sampleUrl: n.sampleUrl,
            previewUrl: n.previewUrl)));
  }

  static bool add(int pid, Booru booru,
      {required String text,
      required String fileUrl,
      required String sampleUrl,
      required Color? backgroundColor,
      required Color? textColor,
      required previewUrl}) {
    final n = Dbs.g.blacklisted.noteBoorus.getByPostIdBooruSync(pid, booru);

    Dbs.g.blacklisted.writeTxnSync(() => Dbs.g.blacklisted.noteBoorus
        .putByPostIdBooruSync(NoteBooru(
            [...n?.text ?? [], text], DateTime.now(),
            postId: pid,
            booru: booru,
            backgroundColor: backgroundColor?.value,
            textColor: textColor?.value,
            fileUrl: fileUrl,
            sampleUrl: sampleUrl,
            previewUrl: previewUrl)));

    return n == null;
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
            backgroundColor: n.backgroundColor,
            textColor: n.textColor,
            fileUrl: n.fileUrl,
            sampleUrl: n.sampleUrl,
            previewUrl: n.previewUrl)));
  }

  static bool remove(int pid, Booru booru, int indx) {
    final n = Dbs.g.blacklisted.noteBoorus.getByPostIdBooruSync(pid, booru);
    if (n == null) {
      return false;
    }
    final t = n.text.toList()..removeAt(indx);
    return Dbs.g.blacklisted.writeTxnSync(() {
      if (t.isEmpty) {
        return Dbs.g.blacklisted.noteBoorus.deleteByPostIdBooruSync(pid, booru);
      } else {
        Dbs.g.blacklisted.noteBoorus.putByPostIdBooruSync(NoteBooru(
            t, DateTime.now(),
            postId: pid,
            booru: booru,
            backgroundColor: n.backgroundColor,
            textColor: n.textColor,
            fileUrl: n.fileUrl,
            sampleUrl: n.sampleUrl,
            previewUrl: n.previewUrl));

        return false;
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

  List<String> currentText() {
    if (isarId == null) {
      return const [];
    }

    return Dbs.g.blacklisted.noteBoorus
        .getByPostIdBooruSync(postId, booru)!
        .text;
  }
}

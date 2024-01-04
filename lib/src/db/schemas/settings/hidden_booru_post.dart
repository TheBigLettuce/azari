// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/cell/cell_data.dart';
import 'package:isar/isar.dart';

part 'hidden_booru_post.g.dart';

@collection
class HiddenBooruPost extends Cell {
  @override
  Id? isarId;

  final String thumbUrl;

  @Index(unique: true, replace: true, composite: [CompositeIndex("booru")])
  final int postId;
  @enumerated
  final Booru booru;

  static bool isHidden(int postId, Booru booru) {
    return Dbs.g.main.hiddenBooruPosts.getByPostIdBooruSync(postId, booru) !=
        null;
  }

  static List<HiddenBooruPost> getAll() {
    return Dbs.g.main.hiddenBooruPosts.where().findAllSync();
  }

  static void addAll(List<HiddenBooruPost> booru) {
    if (booru.isEmpty) {
      return;
    }

    Dbs.g.main
        .writeTxnSync(() => Dbs.g.main.hiddenBooruPosts.putAllSync(booru));
  }

  static void removeAll(List<(int, Booru)> booru) {
    if (booru.isEmpty) {
      return;
    }

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.hiddenBooruPosts
        .deleteAllByPostIdBooruSync(
            booru.map((e) => e.$1).toList(), booru.map((e) => e.$2).toList()));
  }

  HiddenBooruPost(this.booru, this.postId, this.thumbUrl);

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
    return "${booru.string}($postId)";
  }

  @override
  Contentable fileDisplay() {
    throw UnimplementedError();
  }

  @override
  String fileDownloadUrl() {
    throw UnimplementedError();
  }

  @override
  CellData getCellData(bool isList, {required BuildContext context}) {
    return CellData(
        thumb: CachedNetworkImageProvider(thumbUrl),
        name: alias(isList),
        stickers: const []);
  }

  @override
  Key uniqueKey() {
    return ValueKey((postId, booru));
  }
}

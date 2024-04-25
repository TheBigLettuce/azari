// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:gallery/src/db/initalize_db.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:isar/isar.dart";

part "hidden_booru_post.g.dart";

@collection
class HiddenBooruPost implements CellBase, IsarEntryId, Thumbnailable {
  HiddenBooruPost(this.booru, this.postId, this.thumbUrl);
  @override
  Id? isarId;

  final String thumbUrl;

  @Index(unique: true, replace: true, composite: [CompositeIndex("booru")])
  final int postId;
  @enumerated
  final Booru booru;

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((postId, booru));

  @override
  String alias(bool isList) {
    return "$postId ${booru.string}";
  }

  @override
  CellStaticData description() => const CellStaticData();

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

  static StreamSubscription<void> watch(void Function(void) f) {
    return Dbs.g.main.hiddenBooruPosts.watchLazy().listen(f);
  }

  static void removeAll(List<(int, Booru)> booru) {
    if (booru.isEmpty) {
      return;
    }

    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.hiddenBooruPosts.deleteAllByPostIdBooruSync(
        booru.map((e) => e.$1).toList(),
        booru.map((e) => e.$2).toList(),
      ),
    );
  }
}

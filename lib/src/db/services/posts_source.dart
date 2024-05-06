// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/impl/isar/schemas/booru/post.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru_tagging.dart";
import "package:gallery/src/pages/home.dart";
import "package:isar/isar.dart";

abstract interface class PostsSourceService implements ResourceSource<Post> {
  const PostsSourceService();

  factory PostsSourceService.currentMain(
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry,
  ) {
    return switch (currentDb) {
      ServicesImplTable.isar => IsarCurrentBooruSource<PostIsar>(
          db: Dbs.g.main,
          api: api,
          excluded: excluded,
          tags: "",
          entry: entry,
          txPut: (db, l) =>
              db.postIsars.putAllByIdBooruSync(PostIsar.copyTo(l)),
        ),
    };
  }

  factory PostsSourceService.currentTemporary(
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry, {
    required String initialTags,
  }) {
    return switch (currentDb) {
      ServicesImplTable.isar => IsarCurrentBooruSource<PostIsar>(
          db: DbsOpen.secondaryGrid(),
          api: api,
          tags: initialTags,
          excluded: excluded,
          entry: entry,
          txPut: (db, l) =>
              db.postIsars.putAllByIdBooruSync(PostIsar.copyTo(l)),
        ),
    };
  }

  factory PostsSourceService.currentRestored(
    String name,
    BooruAPI api,
    BooruTagging excluded,
    PagingEntry entry, {
    required String initialTags,
  }) {
    return switch (_currentDb) {
      ServicesImplTable.isar => IsarCurrentBooruSource<PostIsar>(
          db: DbsOpen.secondaryGridName(name),
          api: api,
          excluded: excluded,
          entry: entry,
          tags: initialTags,
          txPut: (db, l) =>
              db.postIsars.putAllByIdBooruSync(PostIsar.copyTo(l)),
        ),
    };
  }

  String get tags;
  set tags(String t);
}

class IsarCurrentBooruSource<T extends Post> implements PostsSourceService {
  IsarCurrentBooruSource({
    required this.db,
    required this.api,
    required this.excluded,
    required this.entry,
    required this.txPut,
    required this.tags,
  });

  final Isar db;
  final BooruAPI api;
  final BooruTagging excluded;
  final PagingEntry entry;

  @override
  String tags;

  final void Function(Isar db, Iterable<Post>) txPut;

  int? currentSkipped;

  @override
  void destroy() => db.close(deleteFromDisk: true);

  @override
  T? forIdx(int idx) => db.collection<T>().getSync(idx + 1);

  @override
  T forIdxUnsafe(int idx) => forIdx(idx)!;

  @override
  Future<int> clearRefresh() async {
    db.writeTxnSync(() => db.collection<T>().clearSync());

    currentDb.statisticsGeneral.current.add(refreshes: 1).save();

    entry.updateTime();

    final list = await api.page(0, "", excluded);
    entry.setOffset(0);
    currentSkipped = list.$2;
    db.writeTxnSync(() {
      db.collection<T>().clearSync();
      txPut(
        db,
        list.$1.where(
          (element) =>
              !currentDb.hiddenBooruPost.isHidden(element.id, api.booru),
        ),
      );
    });

    entry.reachedEnd = false;

    return db.collection<T>().count();
  }

  @override
  Future<int> next([int repeatCount = 0]) async {
    if (repeatCount >= 3) {
      return db.collection<T>().countSync();
    }

    if (entry.reachedEnd) {
      return db.collection<T>().countSync();
    }
    final p = db.collection<T>().getSync(db.collection<T>().countSync());
    if (p == null) {
      return db.collection<T>().countSync();
    }

    try {
      final list = await api.fromPost(
        currentSkipped != null && currentSkipped! < p.id
            ? currentSkipped!
            : p.id,
        "",
        excluded,
      );

      if (list.$1.isEmpty && currentSkipped == null) {
        entry.reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = db.collection<T>().countSync();
        txPut(
          db,
          list.$1.where(
            (element) =>
                !currentDb.hiddenBooruPost.isHidden(element.id, api.booru),
          ),
        );

        entry.updateTime();

        if (db.collection<T>().countSync() - oldCount < 3) {
          return next(repeatCount + 1);
        }
      }
    } catch (e, _) {
      return next(repeatCount + 1);
    }

    return db.collection<T>().count();
  }
}

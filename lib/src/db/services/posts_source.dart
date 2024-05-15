// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/pages/home.dart";

abstract interface class PostsSourceService<T>
    extends FilteringResourceSource<T> {
  const PostsSourceService();

  @override
  SourceStorage<T> get backingStorage;

  String get tags;
  set tags(String t);

  void clear();
}

mixin GridPostSourceRefreshNext implements GridPostSource {
  BooruAPI get api;
  BooruTagging get excluded;
  PagingEntry get entry;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  int? currentSkipped;

  @override
  Post? forIdx(int idx) => backingStorage.get(idx);

  @override
  Post forIdxUnsafe(int idx) => forIdx(idx)!;

  @override
  void clear() => backingStorage.clear();

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;

    clear();

    StatisticsGeneralService.db().current.add(refreshes: 1).save();

    entry.updateTime();

    try {
      final list = await api.page(0, "", excluded);
      entry.setOffset(0);
      currentSkipped = list.$2;
      backingStorage.addAll(filter(list.$1));
    } catch (e) {
      progress.error = e;
    }

    entry.reachedEnd = false;

    progress.inRefreshing = false;

    return count;
  }

  @override
  Future<int> next([int repeatCount = 0]) async {
    if (repeatCount >= 3) {
      progress.inRefreshing = false;
      return count;
    }

    if (entry.reachedEnd) {
      return count;
    }

    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;

    final p = forIdx(count - 1);
    if (p == null) {
      return count;
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
        final oldCount = count;
        backingStorage.addAll(filter(list.$1));

        entry.updateTime();

        if (count - oldCount < 3) {
          return next(repeatCount + 1);
        }
      }
    } catch (e, _) {
      return next(repeatCount + 1);
    }

    progress.inRefreshing = false;

    return count;
  }
}

abstract class GridPostSource extends PostsSourceService<Post> {
  @override
  PostsOptimizedStorage get backingStorage;
}

abstract class PostsOptimizedStorage extends SourceStorage<Post> {
  List<Post> get firstFiveNormal;

  List<Post> get firstFiveRelaxed;

  List<Post> get firstFiveAll;
}

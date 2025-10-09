// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/base/home.dart";

abstract interface class PostsSourceService<K, V>
    extends FilteringResourceSource<K, V> {
  const PostsSourceService();

  @override
  SourceStorage<K, V> get backingStorage;

  List<Post> get lastFive;

  String get tags;
  set tags(String t);

  void clear();
}

abstract class GridPostSource extends PostsSourceService<int, Post> {
  Post? get currentlyLast;

  UpdatesAvailable get updatesAvailable;

  static (int, Booru) postTransformKey(Post p) => (p.id, p.booru);
}

mixin BooruPoolsServiceRefreshNext implements BooruPoolsServiceHandle {
  BooruPoolsAPI get api;
  PagingEntry get entry;

  @override
  String? get name;
  @override
  BooruPoolCategory? get category;
  @override
  BooruPoolsOrder get order;

  void Function(BooruPoolsServiceHandle)? get onNextCompleted;
  void Function(BooruPoolsServiceHandle)? get onClearRefreshCompleted;

  @override
  bool get hasNext => true;

  @override
  ClosableRefreshProgress get progress;

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;
    progress.error = null;
    entry.page = 0;

    backingStorage.clear();

    entry.updateTime();

    try {
      final list = await api.search(
        page: 0,
        pageSaver: entry,
        order: order,
        category: category,
        name: name,
      );
      entry.setOffset(0);
      backingStorage.addAll(list);
      onClearRefreshCompleted?.call(this);
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

    if (progress.inRefreshing && repeatCount == 0) {
      return count;
    }
    progress.inRefreshing = true;

    try {
      final list = await api.search(
        page: entry.page + 1,
        pageSaver: entry,
        order: order,
        category: category,
        name: name,
      );

      if (list.isEmpty) {
        entry.reachedEnd = true;
      } else {
        final oldCount = count;
        backingStorage.addAll(list);

        entry.updateTime();
        onNextCompleted?.call(this);

        if (count - oldCount < 3) {
          return await next(repeatCount + 1);
        }
      }
    } catch (e, _) {
      return await next(repeatCount + 1);
    }

    progress.inRefreshing = false;

    return count;
  }
}

mixin GridPostSourcePoolRefreshNext implements GridPostSource {
  BooruPoolsAPI get api;
  BooruPool get pool;
  PagingEntry get entry;

  bool get extraSafeFilters;

  void Function(GridPostSource)? get onNextCompleted;
  void Function(GridPostSource)? get onClearRefreshCompleted;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  void clear() => backingStorage.clear();

  @override
  bool get hasNext => true;

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;
    progress.error = null;
    entry.page = 0;

    clear();

    StatisticsGeneralService.addRefreshes(1);

    entry.updateTime();

    try {
      final list = await api.posts(page: 0, pool: pool, pageSaver: entry);
      if (list.isNotEmpty) {
        updatesAvailable.setCount(list.first.id);
      }
      entry.setOffset(0);
      backingStorage.addAll(
        extraSafeFilters ? filter(list) : filter(list).where(_extraTags),
      );
      onClearRefreshCompleted?.call(this);
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

    if (progress.inRefreshing && repeatCount == 0) {
      return count;
    }
    progress.inRefreshing = true;

    final p = currentlyLast;
    if (p == null) {
      return count;
    }

    try {
      final list = await api.posts(
        page: entry.page + 1,
        pool: pool,
        pageSaver: entry,
      );

      if (list.isEmpty) {
        entry.reachedEnd = true;
      } else {
        final oldCount = count;
        backingStorage.addAll(
          extraSafeFilters ? filter(list) : filter(list).where(_extraTags),
        );

        entry.updateTime();
        onNextCompleted?.call(this);

        if (count - oldCount < 3) {
          return await next(repeatCount + 1);
        }
      }
    } catch (e, _) {
      return await next(repeatCount + 1);
    }

    progress.inRefreshing = false;

    return count;
  }

  bool _extraTags(Post e) {
    for (final e in e.tags) {
      if (BooruAPI.additionalSafetyTags.containsKey(e)) {
        return false;
      }
    }

    return true;
  }
}

mixin GridPostSourceRefreshNext implements GridPostSource {
  BooruAPI get api;
  PagingEntry get entry;
  SafeMode get safeMode;

  void Function(GridPostSource)? get onNextCompleted;
  void Function(GridPostSource)? get onClearRefreshCompleted;

  bool get extraSafeFilters;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  int? currentSkipped;

  @override
  void clear() => backingStorage.clear();

  @override
  bool get hasNext => true;

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;
    progress.error = null;
    entry.page = 0;

    clear();

    StatisticsGeneralService.addRefreshes(1);

    entry.updateTime();

    try {
      final list = await api.page(0, tags, safeMode, pageSaver: entry);
      if (list.$1.isNotEmpty) {
        updatesAvailable.setCount(list.$1.first.id);
      }
      entry.setOffset(0);
      currentSkipped = list.$2;
      backingStorage.addAll(
        extraSafeFilters ? filter(list.$1) : filter(list.$1).where(_extraTags),
      );
      onClearRefreshCompleted?.call(this);
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

    if (progress.inRefreshing && repeatCount == 0) {
      return count;
    }
    progress.inRefreshing = true;

    final p = currentlyLast;
    if (p == null) {
      return count;
    }

    try {
      final (List<Post>, int?) list;
      if (tags.isNotEmpty) {
        list = await api.page(entry.page + 1, tags, safeMode, pageSaver: entry);
      } else {
        list = await api.fromPostId(
          currentSkipped != null && currentSkipped! < p.id
              ? currentSkipped!
              : p.id,
          tags,
          safeMode,
          pageSaver: entry,
        );
      }

      if (list.$1.isEmpty && currentSkipped == null) {
        entry.reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = count;
        backingStorage.addAll(
          extraSafeFilters
              ? filter(list.$1)
              : filter(list.$1).where(_extraTags),
        );

        entry.updateTime();
        onNextCompleted?.call(this);

        if (count - oldCount < 3) {
          return await next(repeatCount + 1);
        }
      }
    } catch (e, _) {
      return await next(repeatCount + 1);
    }

    progress.inRefreshing = false;

    return count;
  }

  bool _extraTags(Post e) {
    for (final e in e.tags) {
      if (BooruAPI.additionalSafetyTags.containsKey(e)) {
        return false;
      }
    }

    return true;
  }
}

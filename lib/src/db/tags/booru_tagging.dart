// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:isar/isar.dart';

import '../../interfaces/booru_tagging.dart';

class TagManager {
  final IsarBooruTagging _excluded;
  final IsarBooruTagging _latest;

  BooruTagging get excluded => _excluded;
  BooruTagging get latest => _latest;

  factory TagManager.fromEnum(Booru booru) {
    final mainGrid = DbsOpen.primaryGrid(booru);

    return TagManager._(mainGrid);
  }

  TagManager._(Isar mainGrid)
      : _excluded = IsarBooruTagging(excludedMode: true, isarCurrent: mainGrid),
        _latest = IsarBooruTagging(excludedMode: false, isarCurrent: mainGrid);
}

class IsarBooruTagging implements BooruTagging {
  const IsarBooruTagging({
    required this.excludedMode,
    required this.isarCurrent,
  });

  final Isar isarCurrent;
  final bool excludedMode;

  @override
  bool exists(Tag tag) {
    return isarCurrent.tags.getByTagIsExcludedSync(tag.tag, excludedMode) !=
        null;
  }

  @override
  List<Tag> get(int i) {
    if (i.isNegative) {
      return isarCurrent.tags
          .filter()
          .isExcludedEqualTo(excludedMode)
          .sortByTimeDesc()
          .findAllSync();
    }

    return isarCurrent.tags
        .filter()
        .isExcludedEqualTo(excludedMode)
        .sortByTimeDesc()
        .limit(i)
        .findAllSync();
  }

  @override
  void add(Tag t) {
    final instance = isarCurrent;

    instance.writeTxnSync(() => instance.tags.putByTagIsExcludedSync(
        t.copyWith(isExcluded: excludedMode, time: DateTime.now())));
  }

  @override
  void delete(Tag t) {
    final instance = isarCurrent;

    instance.writeTxnSync(
        () => instance.tags.deleteByTagIsExcludedSync(t.tag, excludedMode));
  }

  @override
  void clear() {
    final instance = isarCurrent;

    instance.writeTxnSync(() {
      instance.tags.deleteAllSync(
        instance.tags
            .filter()
            .isExcludedEqualTo(excludedMode)
            .findAllSync()
            .map((e) => e.isarId!)
            .toList(),
      );
    });
  }

  @override
  StreamSubscription<void> watch(void Function(void) f, [bool fire = false]) {
    return isarCurrent.tags.watchLazy(fireImmediately: fire).listen(f);
  }
}

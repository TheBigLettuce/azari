// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:isar/isar.dart';

import '../../interfaces/tags.dart';

class IsarBooruTagging implements BooruTagging {
  final Isar isarCurrent;
  final bool excludedMode;

  @override
  List<Tag> get() {
    return isarCurrent.tags
        .filter()
        .isExcludedEqualTo(excludedMode)
        .sortByTimeDesc()
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

  const IsarBooruTagging(
      {required this.excludedMode, required this.isarCurrent});
}

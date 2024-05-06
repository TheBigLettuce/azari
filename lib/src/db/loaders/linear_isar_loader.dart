// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/impl/isar/foundation/initalize_db.dart";
import "package:gallery/src/db/services/impl/isar/foundation/isar_filter.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/filtering/filtering_interface.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:isar/isar.dart";

class LinearIsarLoader<T extends IsarEntryId> {
  LinearIsarLoader(
    CollectionSchema schema,
    this.instance,
    Iterable<T> Function(
      int offset,
      int limit,
      String s,
      SortingMode sort,
      FilteringMode mode,
    ) passFilter,
  ) : filter = IsarFilter(
          instance,
          DbsOpen.temporarySchemas([schema]),
          passFilter,
        );
  final Isar instance;

  final IsarFilter<T> filter;

  T getCell(int i) {
    return filter.to.collection<T>().getSync(i + 1)!;
  }

  int count() {
    return filter.to.collection<T>().countSync();
  }

  void dispose({bool closeInstance = true}) {
    filter.dispose();
    if (closeInstance) {
      instance.close(deleteFromDisk: true);
    }
  }

  void init(
    void Function(Isar instance) loader, {
    FilteringMode d = FilteringMode.noFilter,
  }) {
    loader(instance);
    filter.filter("", d);
  }
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

import '../interfaces/cell.dart';
import 'initalize_db.dart';

class PagingIsarLoader<T extends Cell> {
  final Isar _instance;
  final Iterable<T> Function(int count) loadNext;
  bool _reachedEnd = false;

  Future<int> next() {
    final elems = loadNext(_instance.collection<T>().countSync()).map((e) {
      e.isarId = null;

      return e;
    }).toList();

    if (elems.isEmpty) {
      _reachedEnd = true;
    } else {
      _instance.writeTxnSync(() => _instance.collection<T>().putAllSync(elems));
    }

    return _instance.collection<T>().count();
  }

  Future<int> refresh() {
    _instance.writeTxnSync(() => _instance.clearSync());
    _reachedEnd = false;

    return next();
  }

  T get(int indx) {
    return _instance.collection<T>().getSync(indx + 1)!;
  }

  int count() => _instance.collection<T>().countSync();

  bool reachedEnd() => _reachedEnd;

  Future<bool> dispose({bool force = false}) {
    return _instance.close(deleteFromDisk: force);
  }

  PagingIsarLoader(List<CollectionSchema> schemas, this.loadNext)
      : _instance = DbsOpen.temporarySchemas(schemas);
}

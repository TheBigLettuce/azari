// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/widgets/notifiers/pause_video.dart';
import 'package:isar/isar.dart';

import '../interfaces/booru_tagging.dart';
import '../interfaces/booru/safe_mode.dart';
import 'schemas/grid_state/grid_state.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../interfaces/booru/booru_api.dart';
import '../pages/booru/booru_search_page.dart';
import '../pages/booru/secondary.dart';
import 'schemas/settings/settings.dart';
import 'schemas/tags/tags.dart';
import 'tags/booru_tagging.dart';
import 'initalize_db.dart';

part 'tags/tag_manager.dart';

class StateRestoration {
  final Isar mainGrid;
  GridState _copy;

  GridState get current => mainGrid.gridStates.getByNameSync(_copy.name)!;
  GridState get copy => _copy;

  void updateSession(String newTags) {
    if (_copy.name == mainGrid.name) {
      return;
    }

    final prev = current;

    mainGrid.writeTxnSync(() => mainGrid.gridStates.putSync(
          prev.copy(
            tags: newTags,
            scrollOffset: 0,
            time: DateTime.now(),
          ),
        ));

    _copy = current;
  }

  void updateScrollPosition(double pos) {
    final prev = current;

    mainGrid.writeTxnSync(
      () => mainGrid.gridStates.putSync(
        prev.copy(scrollOffset: pos),
      ),
    );
  }

  int secondaryCount() => mainGrid.gridStates.countSync() - 1;

  void moveToBookmarks(Booru booru) {
    final prev = current;

    mainGrid.writeTxnSync(() => mainGrid.gridStates.deleteSync(prev.id!));

    prev.id = null;

    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.gridStateBoorus.putSync(GridStateBooru(
        booru,
        tags: prev.tags,
        safeMode: prev.safeMode,
        scrollOffset: prev.scrollOffset,
        name: prev.name,
        time: prev.time,
      )),
    );
  }

  void setSafeMode(SafeMode safeMode) {
    final prev = current;

    mainGrid.writeTxnSync(
        () => mainGrid.gridStates.putSync(prev.copy(safeMode: safeMode)));
  }

  void updateTime() {
    final prev = current;

    mainGrid.writeTxnSync(
        () => mainGrid.gridStates.putSync(prev.copy(time: DateTime.now())));
  }

  void removeSelf() {
    if (_copy.name == mainGrid.name) {
      throw "can't remove main grid's state";
    }

    mainGrid
        .writeTxnSync(() => mainGrid.gridStates.deleteByNameSync(_copy.name));
  }

  static StateRestoration insert(
    Isar mainGrid, {
    required String tags,
    required String name,
    required SafeMode safeMode,
  }) {
    mainGrid.writeTxnSync(() => mainGrid.gridStates
        .putByNameSync(GridState.empty(name, tags, safeMode)));
    return StateRestoration._new(mainGrid, name, tags);
  }

  StateRestoration? next() {
    if (_copy.name == mainGrid.name) {
      throw "can't restore next in main StateRestoration";
    }

    mainGrid
        .writeTxnSync(() => mainGrid.gridStates.deleteByNameSync(_copy.name));

    return last();
  }

  StateRestoration? last() {
    var res = mainGrid.gridStates
        .where()
        .nameNotEqualTo(mainGrid.name)
        .sortByTimeDesc()
        .findFirstSync();
    if (res == null) {
      return null;
    }

    return StateRestoration._next(mainGrid, res);
  }

  StateRestoration(this.mainGrid, String name, SafeMode safeMode)
      : _copy = mainGrid.gridStates.getByNameSync(name) ??
            GridState.empty(name, "", safeMode) {
    if (mainGrid.gridStates.getByNameSync(name) == null) {
      mainGrid.writeTxnSync(() => mainGrid.gridStates
          .putByNameSync(GridState.empty(name, "", safeMode)));
    }
  }

  StateRestoration._next(this.mainGrid, this._copy);

  StateRestoration._new(this.mainGrid, String name, String tags)
      : _copy = mainGrid.gridStates.getByNameSync(name)!;
}

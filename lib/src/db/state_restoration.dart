// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

import '../booru/tags/interface.dart';
import '../pages/settings.dart';
import '../schemas/grid_state.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../booru/interface.dart';
import '../pages/booru/random.dart';
import '../pages/booru/secondary.dart';
import '../schemas/tags.dart';
import 'booru_tagging.dart';
import 'isar.dart';

part 'tag_manager.dart';

class StateRestoration {
  final Isar _mainGrid;
  final GridState copy;
  final int? Function()? getPage;

  void updateScrollPosition(double pos, {double? infoPos, int? selectedCell}) {
    final prev = _mainGrid.gridStates.getByNameSync(copy.name)!;

    _mainGrid.writeTxnSync(() => _mainGrid.gridStates.putSync(prev.copy(false,
        scrollPositionGrid: pos,
        scrollPositionTags: infoPos,
        page: getPage?.call(),
        selectedPost: selectedCell)));
  }

  void updateTime() {
    final prev = _mainGrid.gridStates.getByNameSync(copy.name)!;

    _mainGrid.writeTxnSync(() =>
        _mainGrid.gridStates.putSync(prev.copy(false, time: DateTime.now())));
  }

  void removeScrollTagsSelectedPost() {
    if (isRestart) {
      return;
    }
    final prev = _mainGrid.gridStates.getByNameSync(copy.name)!;

    _mainGrid.writeTxnSync(() => _mainGrid.gridStates.putSync(
        prev.copy(true, scrollPositionTags: null, selectedPost: null)));
  }

  void removeSelf() {
    if (copy.name == _mainGrid.name) {
      throw "can't remove main grid's state";
    }

    _mainGrid
        .writeTxnSync(() => _mainGrid.gridStates.deleteByNameSync(copy.name));
  }

  StateRestoration insert({required String tags, required String name}) {
    _mainGrid.writeTxnSync(
        () => _mainGrid.gridStates.putByNameSync(GridState.empty(name, tags)));
    return StateRestoration._new(_mainGrid, name, tags);
  }

  StateRestoration? next() {
    if (copy.name == _mainGrid.name) {
      throw "can't restore next in main StateRestoration";
    }

    _mainGrid
        .writeTxnSync(() => _mainGrid.gridStates.deleteByNameSync(copy.name));

    return last();
  }

  StateRestoration? last() {
    final res = _mainGrid.gridStates.where().sortByTimeDesc().findFirstSync()!;
    if (res.name == _mainGrid.name) {
      return null;
    }

    return StateRestoration._next(_mainGrid, res);
  }

  StateRestoration(Isar mainGrid, String name, this.getPage)
      : _mainGrid = mainGrid,
        copy = mainGrid.gridStates.getByNameSync(name) ??
            GridState.empty(name, "") {
    if (mainGrid.gridStates.getByNameSync(name) == null) {
      mainGrid.writeTxnSync(
          () => mainGrid.gridStates.putByNameSync(GridState.empty(name, "")));
    }
  }

  StateRestoration._next(this._mainGrid, this.copy) : getPage = null;

  StateRestoration._new(this._mainGrid, String name, String tags)
      : copy = _mainGrid.gridStates.getByNameSync(name)!,
        getPage = null;
}

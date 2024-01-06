// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/grid_state/grid_state_booru.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:isar/isar.dart';

import '../interfaces/booru_tagging.dart';
import '../pages/settings/settings_widget.dart';
import '../interfaces/booru/safe_mode.dart';
import 'schemas/grid_state/grid_state.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../interfaces/booru/booru_api_state.dart';
import '../pages/booru/random.dart';
import '../pages/booru/secondary.dart';
import 'schemas/settings/settings.dart';
import 'schemas/tags/tags.dart';
import 'tags/booru_tagging.dart';
import 'initalize_db.dart';

part 'tags/tag_manager.dart';

class StateRestoration {
  final Isar _mainGrid;
  GridState _copy;

  GridState get current => _mainGrid.gridStates.getByNameSync(_copy.name)!;
  GridState get copy => _copy;

  void updatePage(int? page) {
    final prev = current;
    if (prev.page == page) {
      return;
    }

    _mainGrid.writeTxnSync(
        () => _mainGrid.gridStates.putSync(prev.copy(false, page: page)));
  }

  void updateSession(String newTags) {
    if (_copy.name == _mainGrid.name) {
      return;
    }

    final prev = current;

    _mainGrid.writeTxnSync(() => _mainGrid.gridStates.putSync(prev.copy(true,
        tags: newTags,
        scrollPositionGrid: 0,
        selectedPost: 0,
        scrollPositionTags: 0,
        time: DateTime.now(),
        page: null)));

    _copy = current;
  }

  void updateScrollPosition(double pos,
      {double? infoPos, int? selectedCell, int? page}) {
    final prev = current;

    _mainGrid.writeTxnSync(() => _mainGrid.gridStates.putSync(prev.copy(false,
        scrollPositionGrid: pos,
        scrollPositionTags: infoPos,
        page: page,
        selectedPost: selectedCell)));
  }

  int secondaryCount() => _mainGrid.gridStates.countSync() - 1;

  void moveToBookmarks(Booru booru, int? page) {
    final prev = current;

    _mainGrid.writeTxnSync(() => _mainGrid.gridStates.deleteSync(prev.id!));

    prev.id = null;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridStateBoorus.putSync(
        GridStateBooru(booru,
            tags: prev.tags,
            scrollPositionTags: prev.scrollPositionTags,
            selectedPost: prev.selectedPost,
            safeMode: prev.safeMode,
            scrollPositionGrid: prev.scrollPositionGrid,
            name: prev.name,
            time: prev.time,
            page: page)));
  }

  void setSafeMode(SafeMode safeMode) {
    final prev = current;

    _mainGrid.writeTxnSync(() =>
        _mainGrid.gridStates.putSync(prev.copy(false, safeMode: safeMode)));
  }

  void updateTime() {
    final prev = current;

    _mainGrid.writeTxnSync(() =>
        _mainGrid.gridStates.putSync(prev.copy(false, time: DateTime.now())));
  }

  void removeScrollTagsSelectedPost() {
    if (isRestart) {
      return;
    }
    final prev = current;

    _mainGrid.writeTxnSync(() => _mainGrid.gridStates.putSync(
        prev.copy(true, scrollPositionTags: null, selectedPost: null)));
  }

  void removeSelf() {
    if (_copy.name == _mainGrid.name) {
      throw "can't remove main grid's state";
    }

    _mainGrid
        .writeTxnSync(() => _mainGrid.gridStates.deleteByNameSync(_copy.name));
  }

  StateRestoration insert(
      {required String tags,
      required String name,
      required SafeMode safeMode}) {
    _mainGrid.writeTxnSync(() => _mainGrid.gridStates
        .putByNameSync(GridState.empty(name, tags, safeMode)));
    return StateRestoration._new(_mainGrid, name, tags);
  }

  StateRestoration? next() {
    if (_copy.name == _mainGrid.name) {
      throw "can't restore next in main StateRestoration";
    }

    _mainGrid
        .writeTxnSync(() => _mainGrid.gridStates.deleteByNameSync(_copy.name));

    return last();
  }

  StateRestoration? last() {
    var res = _mainGrid.gridStates
        .where()
        .nameNotEqualTo(_mainGrid.name)
        .sortByTimeDesc()
        .findFirstSync();
    if (res == null) {
      return null;
    }

    return StateRestoration._next(_mainGrid, res);
  }

  StateRestoration(Isar mainGrid, String name, SafeMode safeMode)
      : _mainGrid = mainGrid,
        _copy = mainGrid.gridStates.getByNameSync(name) ??
            GridState.empty(name, "", safeMode) {
    if (mainGrid.gridStates.getByNameSync(name) == null) {
      mainGrid.writeTxnSync(() => mainGrid.gridStates
          .putByNameSync(GridState.empty(name, "", safeMode)));
    }
  }

  StateRestoration._next(this._mainGrid, this._copy);

  StateRestoration._new(this._mainGrid, String name, String tags)
      : _copy = _mainGrid.gridStates.getByNameSync(name)!;
}

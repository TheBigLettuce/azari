// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../state_restoration.dart';

typedef InsertGridState = Function(
    {required String tags, required String name, required SafeMode safeMode});

typedef TagManagerWatch = StreamSubscription<dynamic> Function(
    bool, void Function());

sealed class TagManagerType {}

class Restorable implements TagManagerType {}

class Unrestorable implements TagManagerType {}

class TagManager<T extends TagManagerType> {
  final IsarBooruTagging _excluded;
  final IsarBooruTagging _latest;
  final bool _temporary;

  final InsertGridState _insert;

  final TagManagerWatch watch;

  BooruTagging get excluded => _excluded;
  BooruTagging get latest => _latest;

  void onTagPressed(
    BuildContext context,
    Tag t,
    Booru booru,
    bool restore, {
    SafeMode? overrideSafeMode,
  }) {
    t = t.trim();
    if (t.tag.isEmpty) {
      return;
    }

    latest.add(t);

    PauseVideoNotifier.maybePauseOf(context, true);

    if (restore && !_temporary) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        final instance = DbsOpen.secondaryGrid(temporary: false);

        return SecondaryBooruGrid(
          tagManager: this as TagManager<Restorable>,
          noRestoreOnBack: true,
          api: BooruAPIState.fromEnum(booru, page: null),
          restore: _insert(
              tags: t.tag,
              name: instance.name,
              safeMode: overrideSafeMode ?? Settings.fromDb().safeMode),
          instance: instance,
        );
      })).whenComplete(() => PauseVideoNotifier.maybePauseOf(context, false));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return RandomBooruGrid(
          tagManager: this is TagManager<Unrestorable>
              ? this as TagManager<Unrestorable>
              : TagManager._copy(
                  _insert, _excluded, _latest, _temporary, watch),
          api: BooruAPIState.fromEnum(booru, page: null),
          tags: t.tag,
          overrideSafeMode: overrideSafeMode,
        );
      })).whenComplete(() => PauseVideoNotifier.maybePauseOf(context, false));
    }
  }

  static TagManager<Restorable> restorable(
      StateRestoration parent, TagManagerWatch watch) {
    return TagManager._(parent, watch, false);
  }

  static TagManager<Unrestorable> unrestorable(
      StateRestoration parent, TagManagerWatch watch) {
    return TagManager._(parent, watch, true);
  }

  TagManager._(StateRestoration parent, this.watch, this._temporary)
      : _insert = parent.insert,
        _excluded =
            IsarBooruTagging(excludedMode: true, isarCurrent: parent._mainGrid),
        _latest = IsarBooruTagging(
            excludedMode: false, isarCurrent: parent._mainGrid);

  TagManager._copy(
      this._insert, this._excluded, this._latest, this._temporary, this.watch);

  static TagManager<Unrestorable> fromEnum(Booru booru) {
    final mainGrid = DbsOpen.primaryGrid(booru);

    return TagManager._(
        StateRestoration(mainGrid, mainGrid.name, Settings.fromDb().safeMode),
        (fire, f) =>
            mainGrid.tags.watchLazy(fireImmediately: fire).listen((event) {
              f();
            }),
        true);
  }

  static TagManager<Restorable> fromEnumRestorable(Booru booru) {
    final mainGrid = DbsOpen.primaryGrid(booru);

    return TagManager._(
        StateRestoration(mainGrid, mainGrid.name, Settings.fromDb().safeMode),
        (fire, f) =>
            mainGrid.tags.watchLazy(fireImmediately: fire).listen((event) {
              f();
            }),
        false);
  }
}

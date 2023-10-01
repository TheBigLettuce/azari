// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'state_restoration.dart';

class TagManager {
  final IsarBooruTagging _excluded;
  final IsarBooruTagging _latest;
  final bool _temporary;

  final StateRestoration _parent;

  final StreamSubscription Function(bool fire, void Function() f) watch;

  BooruTagging get excluded => _excluded;
  BooruTagging get latest => _latest;

  void onTagPressed(BuildContext context, Tag t, Booru booru, bool restore) {
    t = t.trim();
    if (t.tag.isEmpty) {
      return;
    }

    latest.add(t);

    if (restore && !_temporary) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        final instance = IsarDbsOpen.secondaryGrid(temporary: false);

        return SecondaryBooruGrid(
          tagManager: this,
          noRestoreOnBack: true,
          api: BooruAPI.fromEnum(booru, page: null),
          restore: _parent.insert(tags: t.tag, name: instance.name),
          instance: instance,
        );
      }));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return RandomBooruGrid(
          tagManager: this,
          api: BooruAPI.fromEnum(booru, page: null),
          tags: t.tag,
        );
      }));
    }
  }

  TagManager(StateRestoration parent, this.watch, {bool temporary = false})
      : _parent = parent,
        _temporary = temporary,
        _excluded =
            IsarBooruTagging(excludedMode: true, isarCurrent: parent._mainGrid),
        _latest = IsarBooruTagging(
            excludedMode: false, isarCurrent: parent._mainGrid);

  static TagManager fromEnum(Booru booru, bool temporary) {
    final mainGrid = IsarDbsOpen.primaryGrid(booru);

    return TagManager(
      StateRestoration(mainGrid, mainGrid.name, () => null),
      (fire, f) =>
          mainGrid.tags.watchLazy(fireImmediately: fire).listen((event) {
        f();
      }),
      temporary: temporary,
    );
  }
}

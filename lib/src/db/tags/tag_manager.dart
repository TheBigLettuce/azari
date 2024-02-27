// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../state_restoration.dart';

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

// typedef InsertGridState = Function(Isar mainGrid,
//     {required String tags, required String name, required SafeMode safeMode});

// typedef TagManagerWatch = StreamSubscription<dynamic> Function(
//     bool, void Function());

  // void onTagPressed(
  //   BuildContext context,
  //   Tag t,
  //   Booru booru,
  //   bool restore, {
  //   SelectionGlue<J> Function<J extends Cell>()? generateGlue,
  //   SafeMode? overrideSafeMode,
  //   bool useRootNavigator = false,
  // }) {
  //   //   t = t.trim();
  //   //   if (t.tag.isEmpty) {
  //   //     return;
  //   //   }

  //   //   latest.add(t);

  //   //   PauseVideoNotifier.maybePauseOf(context, true);

  //   //   if (restore && !_temporary) {
  //   //     final instance = DbsOpen.secondaryGrid(temporary: false);
  //   //     final state = _insert(
  //   //       _latest.isarCurrent,
  //   //       tags: t.tag,
  //   //       name: instance.name,
  //   //       safeMode: overrideSafeMode ?? Settings.fromDb().safeMode,
  //   //     );

  //   //     Navigator.of(context, rootNavigator: useRootNavigator)
  //   //         .push(MaterialPageRoute(builder: (context) {
  //   //       return SecondaryBooruGrid(
  //   //         tagManager: this as TagManager<Restorable>,
  //   //         noRestoreOnBack: true,
  //   //         api: BooruAPI.fromEnum(booru, page: null),
  //   //         restore: state,
  //   //         generateGlue: generateGlue,
  //   //         instance: instance,
  //   //       );
  //   //     }));
  //   //     //.whenComplete(() => PauseVideoNotifier.maybePauseOf(context, false));
  //   //   } else {
  //   //     final TagManager<Unrestorable> tagManager = this
  //   //             is TagManager<Unrestorable>
  //   //         ? this as TagManager<Unrestorable>
  //   //         : TagManager._copy(_insert, _excluded, _latest, _temporary, watch);

  //   //     Navigator.of(context, rootNavigator: useRootNavigator)
  //   //         .push(MaterialPageRoute(builder: (context) {
  //   //       return RandomBooruGrid(
  //   //         tagManager: tagManager,
  //   //         api: BooruAPI.fromEnum(booru, page: null),
  //   //         tags: t.tag,
  //   //         overrideSafeMode: overrideSafeMode,
  //   //         generateGlue: generateGlue,
  //   //       );
  //   //     }));
  //   //     //.whenComplete(() => PauseVideoNotifier.maybePauseOf(context, false));
  //   //   }
  // }
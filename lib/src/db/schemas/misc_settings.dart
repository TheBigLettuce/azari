// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:gallery/src/db/initalize_db.dart';
import 'package:isar/isar.dart';

part 'misc_settings.g.dart';

@collection
class MiscSettings {
  final Id id = 0;

  final bool filesExtendedActions;

  const MiscSettings({required this.filesExtendedActions});

  MiscSettings copy({bool? filesExtendedActions}) => MiscSettings(
      filesExtendedActions: filesExtendedActions ?? this.filesExtendedActions);

  static MiscSettings get current =>
      Dbs.g.main.miscSettings.getSync(0) ??
      const MiscSettings(filesExtendedActions: false);

  static void setFilesExtendedActions(bool b) {
    Dbs.g.main.writeTxnSync(() =>
        Dbs.g.main.miscSettings.putSync(current.copy(filesExtendedActions: b)));
  }

  static StreamSubscription<MiscSettings?> watch(void Function(MiscSettings?) f,
      [bool fire = false]) {
    return Dbs.g.main.miscSettings
        .watchObject(0, fireImmediately: fire)
        .listen(f);
  }
}

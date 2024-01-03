// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/grid_settings/booru.dart';

mixin MainGridSettingsMixin<T extends StatefulWidget> on State<T> {
  late final StreamSubscription<GridSettingsBooru?> _settingsWatcher;
  GridSettingsBooru gridSettings = GridSettingsBooru.current;

  void gridSettingsHook() {
    _settingsWatcher = GridSettingsBooru.watch((newSettings) {
      gridSettings = newSettings!;

      setState(() {});
    });
  }

  void disposeGridSettings() {
    _settingsWatcher.cancel();
  }
}

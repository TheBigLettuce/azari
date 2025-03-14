// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:azari/src/db/services/services.dart";
import "package:flutter/material.dart";

mixin CommonGridData<S extends StatefulWidget> on State<S> {
  SettingsService get settingsService;

  StreamSubscription<SettingsData?>? _settingsEvents;

  final gridSeed = math.Random().nextInt(948512342);

  // final GlobalKey<ShellElementState> gridKey = GlobalKey();
  late SettingsData settings;

  void watchSettings() {
    _settingsEvents?.cancel();
    _settingsEvents = settingsService.watch((newSettings) {
      setState(() {
        onNewSettings(settings, newSettings);
        settings = newSettings;
      });
    });
  }

  void onNewSettings(SettingsData prevSettings, SettingsData newSettings) {}

  @override
  void initState() {
    super.initState();

    settings = settingsService.current;
  }

  @override
  void dispose() {
    _settingsEvents?.cancel();

    super.dispose();
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:azari/src/db/services/services.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:flutter/material.dart";

mixin CommonGridData<T extends CellBase, S extends StatefulWidget> on State<S> {
  void watchSettings() {
    _settingsEvents?.cancel();
    _settingsEvents = settings.s.watch((newSettings) {
      setState(() {
        settings = newSettings!;
      });
    });
  }

  StreamSubscription<SettingsData?>? _settingsEvents;

  final gridSeed = math.Random().nextInt(948512342);

  final GlobalKey<GridFrameState<T>> gridKey = GlobalKey();
  SettingsData settings = SettingsService.db().current;

  @override
  void dispose() {
    _settingsEvents?.cancel();

    super.dispose();
  }
}

mixin SettingsWatcherMixin<S extends StatefulWidget> on State<S> {
  StreamSubscription<SettingsData?>? _settingsEvents;

  SettingsData settings = SettingsService.db().current;

  @override
  void initState() {
    super.initState();

    _settingsEvents?.cancel();
    _settingsEvents = settings.s.watch((newSettings) {
      setState(() {
        settings = newSettings!;
      });
    });
  }

  @override
  void dispose() {
    _settingsEvents?.cancel();

    super.dispose();
  }
}

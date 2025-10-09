// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/services/services.dart";
import "package:flutter/material.dart";

class ShellConfiguration extends StatefulWidget {
  const ShellConfiguration({
    super.key,
    required this.gridSettings,
    this.sliver = false,
    required this.child,
  });

  final bool sliver;

  final GridSettingsData gridSettings;

  final Widget child;

  static ShellConfigurationData of(BuildContext context) => maybeOf(context)!;

  static ShellConfigurationData? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_GridConfigurationNotifier>();

    return widget?.data;
  }

  static GridSettingsData gridSettingsOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_GridConfigurationNotifier>()!
      .settings;

  @override
  State<ShellConfiguration> createState() => _ShellConfigurationState();
}

class _ShellConfigurationState extends State<ShellConfiguration> {
  late final StreamSubscription<ShellConfigurationData> _watcher;

  ShellConfigurationData? config;

  @override
  void initState() {
    super.initState();

    config = widget.gridSettings.current;

    _watcher = widget.gridSettings.watch((d) {
      config = d;

      setState(() {});
    });
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (config == null) {
      return widget.sliver
          ? const SliverPadding(padding: EdgeInsets.zero)
          : const SizedBox.shrink();
    }

    return _GridConfigurationNotifier(
      settings: widget.gridSettings,
      data: config!,
      child: widget.child,
    );
  }
}

class _GridConfigurationNotifier extends InheritedWidget {
  const _GridConfigurationNotifier({
    // super.key,
    required this.settings,
    required this.data,
    required super.child,
  });

  final GridSettingsData settings;
  final ShellConfigurationData data;

  @override
  bool updateShouldNotify(_GridConfigurationNotifier oldWidget) =>
      settings != oldWidget.settings || data != oldWidget.data;
}

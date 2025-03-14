// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/services.dart";
import "package:flutter/material.dart";

class ShellConfiguration extends StatefulWidget {
  const ShellConfiguration({
    super.key,
    required this.watch,
    this.sliver = false,
    required this.child,
  });

  final bool sliver;

  final ShellConfigurationWatcher watch;

  final Widget child;

  static ShellConfigurationData of(BuildContext context) => maybeOf(context)!;

  static ShellConfigurationData? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_GridConfigurationNotifier>();

    return widget?.config;
  }

  static ShellConfigurationWatcher watcherOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<
        _GridConfigurationWatcherNotifier>();

    return widget!.watcher;
  }

  @override
  State<ShellConfiguration> createState() => _ShellConfigurationState();
}

class _ShellConfigurationState extends State<ShellConfiguration> {
  late final StreamSubscription<ShellConfigurationData> _watcher;

  ShellConfigurationData? config;

  @override
  void initState() {
    super.initState();

    _watcher = widget.watch(
      (d) {
        config = d;

        setState(() {});
      },
      true,
    );
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

    return _GridConfigurationWatcherNotifier(
      watcher: widget.watch,
      child: _GridConfigurationNotifier(
        config: config!,
        child: widget.child,
      ),
    );
  }
}

class _GridConfigurationWatcherNotifier extends InheritedWidget {
  const _GridConfigurationWatcherNotifier({
    // super.key,
    required this.watcher,
    required super.child,
  });

  final ShellConfigurationWatcher watcher;

  @override
  bool updateShouldNotify(_GridConfigurationWatcherNotifier oldWidget) =>
      watcher != oldWidget.watcher;
}

class _GridConfigurationNotifier extends InheritedWidget {
  const _GridConfigurationNotifier({
    // super.key,
    required this.config,
    required super.child,
  });

  final ShellConfigurationData config;

  @override
  bool updateShouldNotify(_GridConfigurationNotifier oldWidget) =>
      config != oldWidget.config;
}

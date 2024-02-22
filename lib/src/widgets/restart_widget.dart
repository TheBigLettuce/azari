// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/main.dart';

/// RestartWidget is needed for changing the boorus in the settings.
class RestartWidget extends StatefulWidget {
  final Color accentColor;
  final Widget Function(ThemeData dark, ThemeData light) child;

  const RestartWidget({
    super.key,
    required this.accentColor,
    required this.child,
  });

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = buildTheme(Brightness.dark, widget.accentColor);
    final l = buildTheme(Brightness.light, widget.accentColor);

    return KeyedSubtree(
      key: key,
      child: Container(
        color: MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? d.colorScheme.background
            : l.colorScheme.background,
        child: widget.child(d, l).animate(effects: [const FadeEffect()]),
      ),
    );
  }
}

// class NotificationStateNotifier extends InheritedWidget {
//   NotificationStateNotifier({super.key, required super.child});

//   @override
//   bool updateShouldNotify(covariant InheritedWidget oldWidget) {
//     throw UnimplementedError();
//   }
// }

// class NotificationsStateHolder extends StatefulWidget {
//   final Widget child;

//   const NotificationsStateHolder({super.key, required this.child});

//   @override
//   State<NotificationsStateHolder> createState() =>
//       _NotificationsStateHolderState();
// }

// class _NotificationsStateHolderState extends State<NotificationsStateHolder> {
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }

// class AppNotification {}

// class NotificationsArea extends StatefulWidget {
//   const NotificationsArea({required super.key});

//   @override
//   State<NotificationsArea> createState() => NotificationsAreaState();
// }

// class NotificationsAreaState extends State<NotificationsArea> {
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/init_main/build_theme.dart";
import "package:azari/src/init_main/restart_widget.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/settings/settings_list.dart";
import "package:azari/src/ui/material/widgets/gesture_dead_zones.dart";
import "package:flutter/material.dart";

part "is_restart.dart";
part "select_booru.dart";
part "select_theme.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (context) => const SettingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    final padding = EdgeInsets.only(
      bottom: 8 + MediaQuery.paddingOf(context).bottom,
    );

    return SettingsSkeleton(
      l10n.settingsPageName,
      child: SliverPadding(padding: padding, sliver: const SettingsList()),
    );
  }
}

class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton(
    this.pageDescription, {
    super.key,
    this.bottomAppBar,
    this.fab,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    required this.child,
  });

  final bool extendBodyBehindAppBar;
  final bool extendBody;

  final String pageDescription;

  final Widget? bottomAppBar;
  final Widget? fab;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewPaddingOf(context);

    final theme = Theme.of(context);

    final systemGesturesAreZero =
        MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero;

    return AnnotatedRegion(
      value: makeSystemUiOverlayStyle(theme),
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
        bottomNavigationBar: bottomAppBar,
        extendBody: extendBody,
        floatingActionButton: fab,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        drawerEnableOpenDragGesture: systemGesturesAreZero,
        body: GestureDeadZones(
          left: true,
          right: true,
          child: CustomScrollView(
            slivers: [
              SliverAppBar.large(title: Text(pageDescription)),
              SliverPadding(
                padding: EdgeInsets.only(bottom: insets.bottom),
                sliver: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/init_main/build_theme.dart";
import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/pages/other/settings/settings_list.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:flutter/material.dart";

part "is_restart.dart";
part "select_booru.dart";
part "select_theme.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settingsService,
    required this.miscSettingsService,
    required this.galleryService,
    required this.thumbnailService,
  });

  final MiscSettingsService? miscSettingsService;
  final ThumbnailService? thumbnailService;
  final GalleryService? galleryService;

  final SettingsService settingsService;

  static Future<void> open(BuildContext context) {
    final db = Services.of(context);
    final (settingsService, miscSettings, galleryService, thumbnailService) = (
      db.require<SettingsService>(),
      db.get<MiscSettingsService>(),
      db.get<GalleryService>(),
      db.get<ThumbnailService>(),
    );

    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsPage(
          settingsService: settingsService,
          miscSettingsService: miscSettings,
          galleryService: galleryService,
          thumbnailService: thumbnailService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    final padding =
        EdgeInsets.only(bottom: 8 + MediaQuery.paddingOf(context).bottom);

    return SettingsSkeleton(
      l10n.settingsPageName,
      child: SliverPadding(
        padding: padding,
        sliver: SettingsList(
          settingsService: settingsService,
          miscSettingsService: miscSettingsService,
          thumbnailService: thumbnailService,
          galleryService: galleryService,
        ),
      ),
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
      value: navBarStyleForTheme(theme),
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
              SliverAppBar.large(
                title: Text(pageDescription),
              ),
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

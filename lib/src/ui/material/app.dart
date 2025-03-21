// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/welcome_pages.dart";
import "package:flutter/material.dart";

class AppMaterial extends StatefulWidget {
  const AppMaterial({
    super.key,
    required this.color,
    required this.notificationStream,
  });

  final Color color;
  final Stream<NotificationRouteEvent> notificationStream;

  @override
  State<AppMaterial> createState() => _AppMaterialState();
}

class _AppMaterialState extends State<AppMaterial> {
  final restartKey = GlobalKey();

  final progressTab = GlobalProgressTab();
  final selectionEvents = SelectionActions();

  @override
  void dispose() {
    progressTab.dispose();
    selectionEvents.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return selectionEvents.inject(
      progressTab.inject(
        Services.inject(
          TimeTickerStatistics(
            child: RestartWidget(
              accentColor: widget.color,
              key: restartKey,
              child: (d, l) => MaterialApp(
                themeAnimationCurve: Easing.standard,
                themeAnimationDuration: const Duration(milliseconds: 300),
                darkTheme: d,
                theme: l,
                home:
                    _HomeWidget(notificationStream: widget.notificationStream),
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (context) => "Azari",
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeWidget extends StatelessWidget {
  const _HomeWidget({
    // super.key,
    required this.notificationStream,
  });

  final Stream<NotificationRouteEvent> notificationStream;

  @override
  Widget build(BuildContext context) {
    final db = Services.of(context);
    final (settingsSevice, gridBookmarks, favoritePosts, galleryService) = (
      db.require<SettingsService>(),
      db.get<GridBookmarkService>(),
      db.get<FavoritePostSourceService>(),
      db.get<GalleryService>()
    );

    return switch (settingsSevice.current.showWelcomePage) {
      true => WelcomePage(
          galleryService: galleryService,
          settingsService: settingsSevice,
          onEnd: (context) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return Home(
                    stream: notificationStream,
                    settingsService: settingsSevice,
                    gridBookmarks: gridBookmarks,
                    favoritePosts: favoritePosts,
                    galleryService: galleryService,
                  );
                },
              ),
            );
          },
        ),
      false => Home(
          stream: notificationStream,
          settingsService: settingsSevice,
          gridBookmarks: gridBookmarks,
          favoritePosts: favoritePosts,
          galleryService: galleryService,
        ),
    };
  }
}

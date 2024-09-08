// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/build_theme.dart";
import "package:azari/init_main/init_main.dart";
import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/pages/gallery/callback_description.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/home.dart";
import "package:azari/src/plugs/gallery/android/android_api_directories.dart";
import "package:azari/src/plugs/generated/platform_api.g.dart";
import "package:azari/src/plugs/platform_functions.dart";
import "package:azari/src/widgets/copy_move_preview.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/welcome_pages.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

part "main_pick_file.dart";
part "main_quick_view.dart";

void main() async {
  final notificationStream =
      StreamController<NotificationRouteEvent>.broadcast();

  await initMain(false, notificationStream);

  final accentColor = await PlatformApi.current().accentColor();

  final restartKey = GlobalKey();

  runApp(
    RestartWidget(
      accentColor: accentColor,
      key: restartKey,
      child: (d, l, settings) => MaterialApp(
        title: "Azari",
        themeAnimationCurve: Easing.standard,
        themeAnimationDuration: const Duration(milliseconds: 300),
        darkTheme: d,
        theme: l,
        home: settings.showWelcomePage
            ? WelcomePage(
                onEnd: (context) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return Home(stream: notificationStream.stream);
                      },
                    ),
                  );
                },
              )
            : Home(stream: notificationStream.stream),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

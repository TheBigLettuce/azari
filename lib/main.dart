// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/init_main/build_theme.dart";
import "package:gallery/init_main/init_main.dart";
import "package:gallery/init_main/restart_widget.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/plugs/gallery/android/android_api_directories.dart";
import "package:gallery/src/plugs/gallery/android/api.g.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/copy_move_preview.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/welcome_pages.dart";

part "main_pick_file.dart";
part "main_quick_view.dart";

void main() async {
  await initMain(false);

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
        home: settings.showWelcomePage ? const WelcomePage() : const Home(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

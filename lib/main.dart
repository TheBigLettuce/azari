// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/network_status.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/fade_sideways_page_transition_builder.dart";
import "package:gallery/src/widgets/restart_widget.dart";
import "package:gallery/welcome_pages.dart";
import "package:local_auth/local_auth.dart";
// import 'package:google_fonts/google_fonts.dart';
import "package:package_info_plus/package_info_plus.dart";

late final String azariVersion;

ThemeData buildTheme(Brightness brightness, Color accentColor) {
  final type = MiscSettingsService.db().current.themeType;
  final pageTransition = PageTransitionsTheme(
    builders: Map.from(const PageTransitionsTheme().builders)
      ..[TargetPlatform.android] = const FadeSidewaysPageTransitionBuilder(),
  );

  const menuTheme = MenuThemeData(
    style: MenuStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
      ),
    ),
  );

  const popupMenuTheme = PopupMenuThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
  );

  var baseTheme = switch (type) {
    ThemeType.systemAccent => ThemeData(
        brightness: brightness,
        menuTheme: menuTheme,
        popupMenuTheme: popupMenuTheme,
        pageTransitionsTheme: pageTransition,
        useMaterial3: true,
        colorSchemeSeed: accentColor,
      ),
    ThemeType.secretPink => ThemeData(
        brightness: Brightness.dark,
        menuTheme: menuTheme,
        popupMenuTheme: popupMenuTheme,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
        ),
        pageTransitionsTheme: pageTransition,
        useMaterial3: true,
      ),
  };

  final scrollBarTheme = ScrollbarThemeData(
    radius: const ui.Radius.circular(15),
    mainAxisMargin: 0.75,
    thumbColor: WidgetStatePropertyAll(
      baseTheme.colorScheme.onSurface.withOpacity(0.75),
    ),
  );

  switch (type) {
    case ThemeType.systemAccent:
      baseTheme = baseTheme.copyWith(
        scrollbarTheme: scrollBarTheme,
        listTileTheme: baseTheme.listTileTheme.copyWith(
          isThreeLine: false,
          subtitleTextStyle: baseTheme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w300,
          ),
        ),
      );

    case ThemeType.secretPink:
      baseTheme = baseTheme.copyWith(
        scrollbarTheme: scrollBarTheme,
        scaffoldBackgroundColor: baseTheme.colorScheme.surface,
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              baseTheme.colorScheme.onPrimary.withOpacity(0.8),
            ),
            visualDensity: VisualDensity.compact,
            backgroundColor: WidgetStatePropertyAll(
              baseTheme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
        ),
        // buttonTheme: const ButtonThemeData(),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStatePropertyAll(
              baseTheme.textTheme.bodyMedium,
            ),
            foregroundColor: WidgetStatePropertyAll(
              baseTheme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
        ),
      );
  }

  return baseTheme;
}

/// Entrypoint for the second Android's Activity.
/// Picks a file and returns to the app requested.
@pragma("vm:entry-point")
Future<void> mainPickfile() async {
  initLogger();

  WidgetsFlutterBinding.ensureInitialized();
  await initServices();
  initalizeGalleryPlug(true);

  if (PlatformApi.current().requiresPermissions) {
    final auth = LocalAuthentication();

    _canUseAuth = await auth.isDeviceSupported() &&
        await auth.canCheckBiometrics &&
        (await auth.getAvailableBiometrics()).isNotEmpty;
  }

  await initalizeNetworkStatus();

  changeExceptionErrorColors();

  final accentColor = await PlatformApi.current().accentColor();
  azariVersion = (await PackageInfo.fromPlatform()).version;

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    MaterialApp(
      title: "Azari",
      themeAnimationCurve: Easing.standard,
      themeAnimationDuration: const Duration(milliseconds: 300),
      darkTheme: buildTheme(Brightness.dark, accentColor),
      theme: buildTheme(Brightness.light, accentColor),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return Home(
            callback: CallbackDescriptionNested(
                icon: Icons.file_open_rounded,
                AppLocalizations.of(context)!.chooseFileNotice, (chosen) {
              const AndroidApiFunctions().returnUri(chosen.originalUri);
            }),
          );
        },
      ),
    ),
  );
}

void main() async {
  initLogger();

  WidgetsFlutterBinding.ensureInitialized();

  await initServices();
  // await initalizeDownloader();

  changeExceptionErrorColors();

  if (PlatformApi.current().requiresPermissions) {
    final auth = LocalAuthentication();

    _canUseAuth = await auth.isDeviceSupported() &&
        await auth.canCheckBiometrics &&
        (await auth.getAvailableBiometrics()).isNotEmpty;
  }

  initalizeGalleryPlug(false);
  await initalizeNetworkStatus();

  final accentColor = await PlatformApi.current().accentColor();

  final GlobalKey restartKey = GlobalKey();

  await FlutterLocalNotificationsPlugin().initialize(
    const InitializationSettings(
      linux: LinuxInitializationSettings(defaultActionName: "Default action"),
      android: AndroidInitializationSettings("@drawable/ic_notification"),
    ),
    onDidReceiveNotificationResponse: (details) {
      final context = restartKey.currentContext;
      if (context != null) {}
    },
    onDidReceiveBackgroundNotificationResponse: notifBackground,
  );

  await FlutterLocalNotificationsPlugin().cancelAll();

  azariVersion = (await PackageInfo.fromPlatform()).version;

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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

void changeExceptionErrorColors() {
  RenderErrorBox.backgroundColor = Colors.blue.shade800;
  RenderErrorBox.textStyle = ui.TextStyle(color: Colors.white70);
}

bool get canAuthBiometric => _canUseAuth;

SystemUiOverlayStyle navBarStyleForTheme(
  ThemeData theme, {
  bool transparent = true,
  bool elevation = true,
}) =>
    SystemUiOverlayStyle(
      systemNavigationBarIconBrightness: theme.brightness == ui.Brightness.dark
          ? ui.Brightness.light
          : ui.Brightness.dark,
      systemNavigationBarColor: (elevation
              ? ElevationOverlay.applySurfaceTint(
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceTint,
                  3,
                )
              : theme.colorScheme.surface)
          .withOpacity(transparent ? 0.0 : 0.8),
    );

@pragma("vm:entry-point")
void notifBackground(NotificationResponse res) {}

bool _canUseAuth = false;

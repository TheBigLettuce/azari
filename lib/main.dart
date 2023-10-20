// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/plugs/platform_channel.dart';
import 'package:gallery/src/pages/gallery/directories.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/widgets/restart_widget.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'src/pages/home.dart';

late final String azariVersion;

// shamelessly stolen from the Flutter source
class FadeSidewaysPageTransitionBuilder implements PageTransitionsBuilder {
  // Fractional offset from 1/4 screen below the top to fully on screen.
  static final Tween<Offset> _bottomUpTween = Tween<Offset>(
    begin: const Offset(0.25, 0.0),
    end: Offset.zero,
  );
  static final Animatable<double> _fastOutSlowInTween =
      CurveTween(curve: Curves.fastOutSlowIn);
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return SlideTransition(
      position: animation.drive(_bottomUpTween.chain(_fastOutSlowInTween)),
      child: FadeTransition(
        opacity: animation.drive(_fastOutSlowInTween),
        child: child,
      ),
    );
  }

  const FadeSidewaysPageTransitionBuilder();
}

ThemeData _buildTheme(Brightness brightness, Color accentColor) {
  var baseTheme = ThemeData(
    brightness: brightness,
    menuTheme: const MenuThemeData(
        style: MenuStyle(
            shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)))))),
    popupMenuTheme: const PopupMenuThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)))),
    pageTransitionsTheme: PageTransitionsTheme(
        builders: Map.from(const PageTransitionsTheme().builders)
          ..[TargetPlatform.android] =
              const FadeSidewaysPageTransitionBuilder()),
    useMaterial3: true,
    colorSchemeSeed: accentColor,
  );
  baseTheme = baseTheme.copyWith(
      listTileTheme: baseTheme.listTileTheme.copyWith(
          isThreeLine: false,
          subtitleTextStyle: baseTheme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w300,
          )));

  return baseTheme;
}

/// Entrypoint for the second Android's Activity.
/// Picks a file and returns to the app requested.
@pragma('vm:entry-point')
void mainPickfile() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initalizeDb(true);
  initalizeGalleryPlug(true);

  await Permission.photos.request();
  await Permission.videos.request();
  await Permission.storage.request();
  await Permission.accessMediaLocation.request();
  PlatformFunctions.requestManageMedia();

  changeExceptionErrorColors();

  final accentColor = await PlatformFunctions.accentColor();
  azariVersion = (await PackageInfo.fromPlatform()).version;

  runApp(MaterialApp(
    title: 'Ācārya',
    darkTheme: _buildTheme(Brightness.dark, accentColor),
    theme: _buildTheme(Brightness.light, accentColor),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Home(
      callback: CallbackDescriptionNested("Choose file", (chosen) {
        PlatformFunctions.returnUri(chosen.originalUri);
      }),
    ),
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initalizeDb(false);
  await initalizeDownloader();

  changeExceptionErrorColors();

  initalizeGalleryPlug(false);

  final accentColor = await PlatformFunctions.accentColor();

  GlobalKey restartKey = GlobalKey();

  await FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
          linux:
              LinuxInitializationSettings(defaultActionName: "Default action"),
          android: AndroidInitializationSettings('@drawable/ic_notification')),
      onDidReceiveNotificationResponse: (details) {
    final context = restartKey.currentContext;
    if (context != null) {}
  }, onDidReceiveBackgroundNotificationResponse: notifBackground);

  FlutterLocalNotificationsPlugin().cancelAll();

  azariVersion = (await PackageInfo.fromPlatform()).version;

  if (Platform.isAndroid) {
    Permission.notification.request().then((value) async {
      await Permission.photos.request();
      await Permission.videos.request();
      await Permission.storage.request();
      await Permission.accessMediaLocation.request();
      PlatformFunctions.requestManageMedia();
    });
  }

  runApp(RestartWidget(
      key: restartKey,
      child: MaterialApp(
        title: 'Ācārya',
        darkTheme: _buildTheme(Brightness.dark, accentColor),
        theme: _buildTheme(Brightness.light, accentColor),
        home: const Home(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      )));
}

void changeExceptionErrorColors() {
  RenderErrorBox.backgroundColor = Colors.blue.shade800;
  // RenderErrorBox.textStyle = ui.TextStyle(color: Colors.white70);
}

void changeSystemUiOverlay(BuildContext context) {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor:
          Theme.of(context).colorScheme.background.withOpacity(0.5),
    ),
  );
}

@pragma('vm:entry-point')
void notifBackground(NotificationResponse res) {}

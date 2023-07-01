// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/gallery/uploader/uploader.dart';
import 'package:gallery/src/pages/booru_scroll.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/grid_restore.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as scroll_pos;
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

void main() async {
  if (Platform.isLinux) {
    await Isar.initializeIsarCore(libraries: {
      Abi.current(): path.joinAll(
          [path.dirname(Platform.resolvedExecutable), "lib", "libisar.so"])
    });

    MediaKit.ensureInitialized();
  }

  WidgetsFlutterBinding.ensureInitialized();
  await initalizeIsar();
  await initalizeDownloader();
  initalizeUploader();
  initalizeBooruTags();

  const platform = MethodChannel("lol.bruh19.azari.gallery");

  int color;

  try {
    color = await platform.invokeMethod("accentColor");
  } catch (_) {
    color = Colors.limeAccent.value;
  }
  final accentColor = Color(color);

  GlobalKey<BooruScrollState> key = GlobalKey();

  FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
          linux:
              LinuxInitializationSettings(defaultActionName: "Default action"),
          android: AndroidInitializationSettings('@drawable/ic_notification')),
      onDidReceiveNotificationResponse: (details) {
    var context = key.currentContext;
    if (context != null) {
      selectDestination(context, kBooruGridDrawerIndex, kDownloadsDrawerIndex);
    }
  }, onDidReceiveBackgroundNotificationResponse: notifBackground);

  runApp(MaterialApp(
    title: 'Ācārya',
    darkTheme: _buildTheme(Brightness.dark, accentColor),
    theme: _buildTheme(Brightness.light, accentColor),
    home: const Entry(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routes: {
      "/senitel": (context) => Container(),
      "/booru": (context) {
        var arguments = ModalRoute.of(context)!.settings.arguments;
        if (arguments != null) {
          var list = isar().gridRestores.where().findAllSync();
          for (var element in list) {
            removeSecondaryGrid(element.path);
          }
        }

        var scroll =
            isar().scrollPositionPrimarys.getSync(fastHash(getBooru().domain));

        return BooruScroll.primary(
          key: key,
          initalScroll: scroll != null ? scroll.pos : 0,
          time: scroll != null ? scroll.time : DateTime.now(),
          isar: isar(),
          clear: arguments != null ? true : false,
        );
      }
    },
  ));
}

@pragma('vm:entry-point')
void notifBackground(NotificationResponse res) {}

class Entry extends StatelessWidget {
  const Entry({super.key});

  @override
  Widget build(BuildContext context) {
    var settings = isar().settings.getSync(0) ?? Settings.empty();
    showDialog(String s) {
      Navigator.of(context).push(DialogRoute(
          context: context,
          builder: (context) => AlertDialog(
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.ok))
                ],
                content: Text(s),
              )));
    }

    restore() {
      if (Platform.isAndroid) {
        Permission.notification.request();

        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
              systemNavigationBarColor:
                  Theme.of(context).colorScheme.background.withOpacity(0.5)),
        );
      }

      restoreState(context, true);
    }

    bool validUri(String s) => Uri.tryParse(s) != null;

    if (settings.path.isEmpty || !validUri(settings.path)) {
      return IntroductionScreen(
        pages: [
          PageViewModel(
            title: AppLocalizations.of(context)!.pickDirectory,
            bodyWidget: TextButton(
              onPressed: () async {
                for (true;;) {
                  if (await chooseDirectory(showDialog)) {
                    break;
                  }
                }

                restore();
              },
              child: Text(AppLocalizations.of(context)!.pick),
            ),
          )
        ],
        showDoneButton: false,
        next: Text(AppLocalizations.of(context)!.next),
      );
    }

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      restore();
    });

    return Container();
  }
}

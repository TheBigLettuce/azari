// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/platform_channel.dart';
import 'package:gallery/src/gallery/android_api/android_directories.dart';
import 'package:gallery/src/gallery/android_api/api.g.dart';
import 'package:gallery/src/gallery/android_api/android_api_directories.dart';
import 'package:gallery/src/gallery/uploader/uploader.dart';
import 'package:gallery/src/pages/booru_scroll.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/grid_restore.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as scroll_pos;
import 'package:gallery/src/schemas/settings.dart';
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

/// This needed for the state restoration.
class Dummy extends StatelessWidget {
  const Dummy({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.scheduleFrameCallback(
      (timeStamp) {
        _globalTab.restoreState(context);
      },
    );

    return Container();
  }
}

/// Entrypoint for the second Android's Activity.
/// Picks a file and returns to the app requested.
@pragma('vm:entry-point')
void mainPickfile() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initalizeIsar(true);
  initPostTags();
  GalleryApi.setup(GalleryImpl(true));

  await Permission.photos.request();
  await Permission.videos.request();
  await Permission.storage.request();
  await Permission.accessMediaLocation.request();
  PlatformFunctions.requestManageMedia();

  changeErrorColors();

  final accentColor = await PlatformFunctions.accentColor();

  runApp(MaterialApp(
    title: 'Ācārya',
    darkTheme: _buildTheme(Brightness.dark, accentColor),
    theme: _buildTheme(Brightness.light, accentColor),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        changeOverlay(context);

        return AndroidDirectories(
          noDrawer: true,
          nestedCallback: CallbackDescriptionNested("Choose file", (chosen) {
            PlatformFunctions.returnUri(chosen.originalUri);
          }),
        );
      },
    ),
  ));
}

void changeErrorColors() {
  RenderErrorBox.backgroundColor = Colors.blue.shade800;
  RenderErrorBox.textStyle = ui.TextStyle(color: Colors.white70);
}

void main() async {
  if (Platform.isLinux) {
    await Isar.initializeIsarCore(libraries: {
      Abi.current(): path.joinAll(
          [path.dirname(Platform.resolvedExecutable), "lib", "libisar.so"])
    });

    MediaKit.ensureInitialized();
  }

  changeErrorColors();

  WidgetsFlutterBinding.ensureInitialized();
  await initalizeIsar(false);
  await initalizeDownloader();
  initalizeUploader();
  initPostTags();

  if (Platform.isAndroid) {
    GalleryApi.setup(GalleryImpl(false));
  }

  final accentColor = await PlatformFunctions.accentColor();

  GlobalKey restartKey = GlobalKey();

  await FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
          linux:
              LinuxInitializationSettings(defaultActionName: "Default action"),
          android: AndroidInitializationSettings('@drawable/ic_notification')),
      onDidReceiveNotificationResponse: (details) {
    var context = restartKey.currentContext;
    if (context != null) {
      selectDestination(context, kComeFromRandom, kDownloadsDrawerIndex);
    }
  }, onDidReceiveBackgroundNotificationResponse: notifBackground);

  FlutterLocalNotificationsPlugin().cancelAll();

  _globalTab = makeGridTab(getSettings().selectedBooru);

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
        home: getSettings().path == "" ? const Entry() : const Dummy(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          "/senitel": (context) => Container(),
          "/booru": (context) {
            changeOverlay(context);

            var grids = getTab();

            var arguments = ModalRoute.of(context)!.settings.arguments;
            if (arguments != null) {
              var list = grids.instance.gridRestores.where().findAllSync();
              for (var element in list) {
                grids.removeSecondaryGrid(element.path);
              }
            }

            var scroll = grids.instance.scrollPositionPrimarys.getSync(0);

            return BooruScroll.primary(
              initalScroll: scroll != null ? scroll.pos : 0,
              time: scroll != null ? scroll.time : DateTime.now(),
              grids: grids,
              booruPage: scroll?.page,
              clear: arguments != null ? true : false,
            );
          }
        },
      )));
}

void changeOverlay(BuildContext context) {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
        systemNavigationBarColor:
            Theme.of(context).colorScheme.background.withOpacity(0.5)),
  );
}

late GridTab _globalTab;

GridTab getTab() => _globalTab;

Settings getSettings() {
  return settingsIsar().settings.getSync(0) ?? Settings.empty();
}

class BooruArguments {}

/// RestartWidget is needed for changing the boorus in the settings.
class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    // this is very important, because getTab usage is random
    _globalTab = makeGridTab(getSettings().selectedBooru);
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: key, child: widget.child);
  }
}

@pragma('vm:entry-point')
void notifBackground(NotificationResponse res) {}

/// Currently forces the user to choose a directory.
class Entry extends StatelessWidget {
  const Entry({super.key});

  @override
  Widget build(BuildContext context) {
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
      Navigator.pushReplacementNamed(context, "/booru");
    }

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
}

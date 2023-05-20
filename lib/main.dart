import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/booru/infinite_scroll.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/schemas/grid_restore.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as scroll_pos;
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/schemas/tags.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

ThemeData _buildTheme(Brightness brightness, Color accentColor) {
  var baseTheme = ThemeData(
    fontFamily: 'OpenSans',
    brightness: brightness,
    useMaterial3: true,
    colorSchemeSeed: accentColor,
  );

  return baseTheme;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initalizeIsar();

  const platform = MethodChannel("lol.bruh19.azari.gallery");

  int color = await platform.invokeMethod("accentColor");

  final accentColor = Color(color);

  FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification')),
      onDidReceiveNotificationResponse: (details) {},
      onDidReceiveBackgroundNotificationResponse: notifBackground);

  runApp(MaterialApp(
    title: 'Ācārya',
    darkTheme: _buildTheme(Brightness.dark, accentColor),
    theme: _buildTheme(Brightness.light, accentColor),
    initialRoute: "/",
    routes: {
      "/": (context) => const Entry(),
      "/booru": (context) {
        var arguments = ModalRoute.of(context)!.settings.arguments;
        if (arguments != null) {
          var list = isar().gridRestores.where().findAllSync();
          for (var element in list) {
            removeSecondaryGrid(element.path);
          }
        }

        var scroll = isar()
            .scrollPositionPrimarys
            .getSync(fastHash(getBooru().domain()));

        return BooruScroll.primary(
          initalScroll: scroll != null ? scroll.pos : 0,
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
                      child: const Text("ok"))
                ],
                content: Text(s),
              )));
    }

    restore() {
      Permission.notification.request();

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            systemNavigationBarColor:
                Theme.of(context).colorScheme.background.withOpacity(0.5)),
      );

      restoreState(context, true);
      if (settings.enableGallery && !settings.booruDefault) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) {
          return const Directories();
        }));
      }
    }

    bool validUri(String s) => Uri.tryParse(s) != null;

    if (settings.path.isEmpty || !validUri(settings.path)) {
      return IntroductionScreen(
        pages: [
          PageViewModel(
            title: "Choose download directory",
            bodyWidget: TextButton(
              onPressed: () async {
                await chooseDirectory(showDialog);

                restore();
              },
              child: const Text("pick"),
            ),
          )
        ],
        showDoneButton: false,
        next: const Text("next"),
      );
    }

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      restore();
    });

    return Container();
  }
}

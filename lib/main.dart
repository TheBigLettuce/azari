import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/booru/infinite_scroll.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/schemas/grid_restore.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as scroll_pos;
import 'package:gallery/src/schemas/secondary_grid.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'src/models/directory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initalizeIsar();

  FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification')),
      onDidReceiveNotificationResponse: (details) {},
      onDidReceiveBackgroundNotificationResponse: notifBackground);

  runApp(ChangeNotifierProvider(
    create: (_) {
      var img = DirectoryModel();
      // img.refresh();

      return img;
    },
    child: MaterialApp(
      title: 'Welcome to Flutter',
      darkTheme: ThemeData.dark(useMaterial3: true),
      theme: ThemeData(
        useMaterial3: true,
        /*appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),*/
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => const Entry(),
        "/booru": (context) {
          var arguments = ModalRoute.of(context)!.settings.arguments;
          var scroll = isar()
              .scrollPositionPrimarys
              .getSync(fastHash(getBooru().domain()));

          return BooruScroll.primary(
            initalScroll: scroll != null ? scroll.pos : 0,
            isar: isar(),
            clear: arguments != null ? arguments as bool : false,
          );
        }
      },
      //home: const Entry(),
    ),
  ));
}

@pragma('vm:entry-point')
void notifBackground(NotificationResponse res) {}

class Entry extends StatelessWidget {
  const Entry({super.key});

  @override
  Widget build(BuildContext context) {
    return () {
          List<PageViewModel> list = [];

          var provider = Provider.of<DirectoryModel>(context);

          if (!provider.isDirectorySet()) {
            list.add(
              PageViewModel(
                title: "Choose download directory",
                footer: provider.directorySetError != null
                    ? Center(
                        child: Text(
                          provider.directorySetError!,
                        ),
                      )
                    : null,
                bodyWidget: TextButton(
                  onPressed: provider.pickDirectory,
                  child: const Text("pick"),
                ),
              ),
            );
          }

          return list.isEmpty
              ? null
              : IntroductionScreen(
                  pages: list,
                  //done: Text("ok"),
                  showDoneButton: false,
                  next: const Text("next"),
                );
        }() ??
        FutureBuilder(
            future: Provider.of<DirectoryModel>(context, listen: false)
                .initalize(Theme.of(context).colorScheme.background),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
                  var settings = isar().settings.getSync(0)!;
                  restoreState(context, true);
                  if (settings.enableGallery && !settings.booruDefault) {
                    Navigator.of(context)
                        .pushReplacement(MaterialPageRoute(builder: (context) {
                      return const Directories();
                    }));
                  }
                });
              }

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            });
  }
}

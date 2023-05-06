import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/booru/infinite_scroll.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as scroll_pos;
import 'package:gallery/src/schemas/settings.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'src/models/directory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initalizeIsar();

  FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher')),
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
          var scroll = isar().scrollPositions.getSync(0);
          return BooruScroll(
            initalScroll: scroll != null ? scroll.pos : 0,
            isar: isar(),
            updateScrollPosition: (pos) {
              print("pos set");
              isar().writeTxn(() =>
                  isar().scrollPositions.put(scroll_pos.ScrollPosition(pos)));
            },
          );
        }
      },
      //home: const Entry(),
    ),
  ));
}

@pragma('vm:entry-point')
void notifBackground(NotificationResponse res) {}

//const platform = MethodChannel('lol.bruh19.azari.gallery/mediastore');

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
                title: "Choose default directory",
                footer: provider.directorySetError != null
                    ? Text(provider.directorySetError!)
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
                  var settings = isar().settings.getSync(0);
                  if (settings!.enableGallery) {
                    if (settings.booruDefault) {
                      Navigator.of(context).pushReplacementNamed("/booru");
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => const Directories()));
                    }
                  } else {
                    Navigator.of(context).pushReplacementNamed("/booru");
                  }
                });
              }

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            });
  }
}

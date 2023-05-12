import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/booru/infinite_scroll.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as scroll_pos;
import 'package:gallery/src/schemas/scroll_position_search.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'src/models/directory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initalizeIsar();

  FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings(
              '@drawable/ic_launcher_foreground')),
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
                    var posTags = isar()
                        .scrollPositionTags
                        .getSync(fastHash(getBooru().domain()));
                    if (posTags != null && posTags.tags.isNotEmpty) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BooruScroll.restore(
                              isar: isarPostsOnly(),
                              tags: posTags.tags,
                              initalScroll: posTags.pos,
                              booruPage: posTags.page,
                            ),
                          ));
                    }
                  }
                });
              }

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            });
  }
}

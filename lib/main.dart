import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/booru/booru.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';

import 'package:file_picker/file_picker.dart';
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
      theme: ThemeData(
        useMaterial3: true,
        /*appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),*/
      ),
      home: const Entry(),
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

          if (!provider.isServerAddressSet()) {
            list.add(PageViewModel(
                title: "Set server address",
                footer: provider.serverAddrSetError != null
                    ? Text(provider.serverAddrSetError!)
                    : null,
                bodyWidget: TextField(
                  keyboardType: TextInputType.url,
                  onSubmitted: provider.setServerAddress,
                )));
          }

          if (!provider.isDeviceIdSet() && provider.isServerAddressSet()) {
            list.add(PageViewModel(
                title: "Set DeviceID",
                footer: provider.deviceIdSetError != null
                    ? Text(provider.deviceIdSetError!)
                    : null,
                bodyWidget: TextField(
                  onSubmitted: provider.setDeviceId,
                )));
          }

          if (!provider.isDirectorySet() && provider.isServerAddressSet()) {
            list.add(
              PageViewModel(
                title: "Choose default directory",
                footer: provider.directorySetError != null
                    ? Text(provider.directorySetError!)
                    : null,
                bodyWidget: TextButton(
                  child: const Text("pick"),
                  onPressed: () async {
                    var pickedDir =
                        await FilePicker.platform.getDirectoryPath();
                    if (pickedDir == null ||
                        pickedDir == "" ||
                        FileStat.statSync(pickedDir).type ==
                            FileSystemEntityType.notFound) {
                      provider.directorySetError = "Path is invalid";
                      return;
                    }

                    provider.setDirectory(pickedDir);
                  },
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
                .initalize(context),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return const Booru();
              }

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            });
  }
}

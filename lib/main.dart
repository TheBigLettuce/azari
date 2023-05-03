import 'dart:io';
import 'package:gallery/src/booru/booru.dart';
import 'package:gallery/src/drawer.dart';
//import 'dart:io';
//import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
//import 'package:async/async.dart' as async;

import 'src/image/grid.dart';
import 'src/image/images.dart';
import 'src/models/directory.dart';
import 'src/settings.dart';
//import 'package:permission_handler/permission_handler.dart';
//import 'package:web_socket_channel/io.dart';
//import 'package:web_socket_channel/web_socket_channel.dart';

//import 'package:transparent_image/transparent_image.dart';
//import 'package:convert/convert.dart' as convert;

//import 'dart:async';
//import 'package:transparent_image/transparent_image.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("settings");

  runApp(const MyApp());
}

//const platform = MethodChannel('lol.bruh19.azari.gallery/mediastore');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
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
    );
  }
}

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

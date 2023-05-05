import 'package:flutter/material.dart';
import 'package:gallery/src/booru/infinite_scroll.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/lost_downloads.dart';
import 'package:gallery/src/schemas/settings.dart' as scheme_settings;

import 'booru/booru.dart';
import 'settings.dart';

Widget makeDrawer(BuildContext context, bool showBooru) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        const DrawerHeader(child: Text("Gallery")),
        showBooru
            ? ListTile(
                title: const Text("Booru"),
                leading: const Icon(Icons.image),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, "/booru");
                },
              )
            : ListTile(
                title: const Text("Gallery"),
                leading: const Icon(Icons.photo_album),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                    return const Directories();
                  }));
                },
              ),
        ListTile(
          title: const Text("Downloads"),
          leading: const Icon(Icons.download),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LostDownloads(),
                ));
          },
        ),
        ListTile(
          title: const Text("Settings"),
          leading: const Icon(Icons.settings),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Settings()));
          },
        )
      ],
    ),
  );
}

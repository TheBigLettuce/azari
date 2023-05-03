import 'package:flutter/material.dart';
import 'package:gallery/src/directories.dart';

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
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => const Booru()));
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/search.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/lost_downloads.dart';
import 'settings.dart';

Widget makeDrawer(BuildContext context, bool showBooru, bool showGallery) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: () {
        List<Widget> list = [
          DrawerHeader(
              child: Center(
            child: const Icon(
              IconData(0x963F),
            ).animate().shake(),
          )),
        ];

        if (showGallery) {
          if (showBooru) {
            list.add(ListTile(
              title: const Text("Booru"),
              leading: const Icon(Icons.image),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ));
          } else {
            list.add(ListTile(
              title: const Text("Gallery"),
              leading: const Icon(Icons.photo_album),
              onTap: () {
                //Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const Directories();
                }));
              },
            ));
          }
        }

        list.addAll([
          ListTile(
              title: const Text("Tags"),
              leading: const Icon(Icons.tag),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchBooru(),
                    ));
              }),
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
        ]);

        return list;
      }(),
    ),
  );
}

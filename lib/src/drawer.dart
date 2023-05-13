import 'package:flutter/material.dart';
import 'package:gallery/src/booru/infinite_scroll.dart';
import 'package:gallery/src/booru/search.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/lost_downloads.dart';
import 'package:gallery/src/schemas/settings.dart' as scheme_settings;
import 'settings.dart';

Widget makeDrawer(BuildContext context, bool showBooru) {
  var settings = isar().settings.getSync(0);

  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: () {
        List<Widget> list = [
          const DrawerHeader(child: Text("Gallery")),
        ];

        if (settings!.enableGallery) {
          if (showBooru) {
            list.add(ListTile(
              title: const Text("Booru"),
              leading: const Icon(Icons.image),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, "/booru");
              },
            ));
          } else {
            list.add(ListTile(
              title: const Text("Gallery"),
              leading: const Icon(Icons.photo_album),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) {
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
                      builder: (context) => SearchBooru(
                        onSubmitted: (tag) {
                          newSecondaryGrid().then((value) {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) {
                              return BooruScroll.secondary(
                                isar: value,
                                tags: tag,
                              );
                            }));
                          }).onError((error, stackTrace) {
                            print(error);
                          });
                        },
                      ),
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

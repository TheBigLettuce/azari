import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/models/directory.dart';
import 'package:gallery/src/schemas/settings.dart' as schema_settings;
import 'package:provider/provider.dart';

import 'schemas/settings.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final StreamSubscription<schema_settings.Settings?> _watcher;
  schema_settings.Settings? _settings = isar().settings.getSync(0);
  bool defaultChanged = false;
  bool booruChanged = false;
  bool listViewChanged = false;
  bool elemRowNumbChanged = false;

  @override
  void initState() {
    super.initState();

    _watcher =
        isar().settings.watchObject(0, fireImmediately: true).listen((event) {
      setState(() {
        _settings = event;
      });
    });
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  void _popBooru() {
    Navigator.of(context)
        .pushReplacementNamed("/booru", arguments: booruChanged);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (defaultChanged) {
          if (_settings!.booruDefault) {
            _popBooru();
          } else {
            Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (context) {
              return const Directories();
            }));
          }
        }

        if (_settings!.booruDefault && booruChanged ||
            elemRowNumbChanged ||
            listViewChanged) {
          _popBooru();
        }

        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: ListView(children: [
          ListTile(
            title: const Text("Default Directory"),
            subtitle: Text(_settings!.path),
            trailing: TextButton(
              onPressed: Provider.of<DirectoryModel>(context, listen: false)
                  .pickDirectory,
              child: const Text("pick new"),
            ),
          ),
          ListTile(
            title: const Text("Enable gallery"),
            trailing: Switch(
              onChanged: null,
              value: _settings!.enableGallery,
            ),
          ),
          ListTile(
            title: const Text("Booru default screen"),
            subtitle: const Text(
                "If enabled, makes the booru screen the default one, when the app opens."),
            trailing: Switch(
              onChanged: _settings!.enableGallery
                  ? (value) {
                      defaultChanged = true;
                      isar().writeTxnSync(() {
                        isar().settings.putSync(_settings!
                            .copy(booruDefault: !_settings!.booruDefault));
                      });
                    }
                  : null,
              value: _settings!.booruDefault,
            ),
          ),
          ListTile(
            title: const Text("Selected booru"),
            trailing: DropdownButton<Booru>(
              value: _settings!.selectedBooru,
              items: [
                DropdownMenuItem(
                  value: Booru.danbooru,
                  child: Text(Booru.danbooru.string),
                ),
                DropdownMenuItem(
                  value: Booru.gelbooru,
                  child: Text(Booru.gelbooru.string),
                )
              ],
              onChanged: (value) {
                if (value != _settings!.selectedBooru) {
                  booruChanged = true;
                  isar().writeTxnSync(() => isar()
                      .settings
                      .putSync(_settings!.copy(selectedBooru: value)));
                }
              },
            ),
          ),
          ListTile(
              title: const Text("Image display quality"),
              leading: IconButton(
                icon: const Icon(Icons.info_outlined),
                onPressed: () {
                  Navigator.of(context).push(DialogRoute(
                      context: context,
                      builder: (context) {
                        return const AlertDialog(
                          content: Text("Download quality is always Original."),
                        );
                      }));
                },
              ),
              trailing: DropdownButton<DisplayQuality>(
                value: _settings!.quality,
                items: [
                  DropdownMenuItem(
                      value: DisplayQuality.original,
                      child: Text(DisplayQuality.original.string)),
                  DropdownMenuItem(
                    value: DisplayQuality.sample,
                    child: Text(DisplayQuality.sample.string),
                  )
                ],
                onChanged: (value) {
                  if (value != _settings!.quality) {
                    isar().writeTxnSync(() => isar()
                        .settings
                        .putSync(_settings!.copy(quality: value)));
                  }
                },
              )),
          ListTile(
            title: const Text("List view"),
            leading: IconButton(
                onPressed: () {
                  Navigator.of(context).push(DialogRoute(
                      context: context,
                      builder: (context) => const AlertDialog(
                            content: Text(
                                "Number of elements is always 20 in the list view."),
                          )));
                },
                icon: const Icon(Icons.info_outline)),
            subtitle: const Text(
                "If enabled shows elements as a list instead of a grid."),
            trailing: Switch(
              value: _settings!.listViewBooru,
              onChanged: (value) {
                if (value != _settings!.listViewBooru) {
                  listViewChanged = true;
                  isar().writeTxnSync(() => isar()
                      .settings
                      .putSync(_settings!.copy(listViewBooru: value)));
                }
              },
            ),
          ),
          ListTile(
              title: const Text("Number of elements per row"),
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).push(DialogRoute(
                      context: context,
                      builder: (context) => const AlertDialog(
                          content: Text(
                              "Number of elements per refresh starts at 20. If number of elements per row is more than two, "
                              "number of elements per refresh increases by 10 per increase. So, if number of elements "
                              "per row is three, then number of elements per refresh will be 30."))));
                },
                icon: const Icon(Icons.info_outline),
              ),
              trailing: DropdownButton<int>(
                value: _settings!.picturesPerRow,
                items: const [
                  DropdownMenuItem(value: 2, child: Text("2")),
                  DropdownMenuItem(value: 3, child: Text("3")),
                  DropdownMenuItem(value: 4, child: Text("4")),
                  DropdownMenuItem(value: 5, child: Text("5")),
                  DropdownMenuItem(value: 6, child: Text("6"))
                ],
                onChanged: _settings!.listViewBooru
                    ? null
                    : (value) {
                        if (value != _settings!.picturesPerRow) {
                          elemRowNumbChanged = true;
                          isar().writeTxnSync(() => isar()
                              .settings
                              .putSync(_settings!.copy(picturesPerRow: value)));
                        }
                      },
              ))
        ]),
      ),
    );
  }
}

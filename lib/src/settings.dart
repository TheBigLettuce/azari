import 'package:flutter/material.dart';
import 'package:gallery/src/booru/booru.dart';
import 'package:gallery/src/booru/infinite_scroll.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/models/directory.dart';
import 'package:gallery/src/schemas/settings.dart' as schema_settings;
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool defunct = false;
  final Stream<schema_settings.Settings?> _watcher =
      isar().settings.watchObject(0, fireImmediately: true);
  schema_settings.Settings? _settings = isar().settings.getSync(0);
  bool viewChanged = false;
  bool defaultChanged = false;

  @override
  void initState() {
    super.initState();

    _watcher.listen((e) {
      if (!defunct) {
        setState(() {
          _settings = e;
        });
      }
    });
  }

  @override
  void dispose() {
    defunct = true;

    super.dispose();
  }

  void _popBooru() {
    Navigator.of(context).pushReplacementNamed("/booru");
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
        } else {
          if (_settings!.booruDefault && viewChanged) {
            _popBooru();
          }
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
            title: const Text("Scrollview Booru"),
            subtitle: const Text(
                "If turned on, enables infinite scroll instead of paging."),
            trailing: Switch(
              value: _settings!.scrollView,
              onChanged: (value) {
                viewChanged = true;
                var settings = isar().settings.getSync(0) ??
                    schema_settings.Settings.empty();
                isar().writeTxnSync(() {
                  isar().settings.putSync(
                      settings.copy(scrollView: !_settings!.scrollView));
                });
              },
            ),
          ),
          ListTile(
            title: const Text("Booru default screen"),
            subtitle: const Text(
                "If enabled, makes the booru screen the default one, when the app opens."),
            trailing: Switch(
              onChanged: (value) {
                defaultChanged = true;
                var settings = isar().settings.getSync(0) ??
                    schema_settings.Settings.empty();
                isar().writeTxnSync(() {
                  isar().settings.putSync(
                      settings.copy(booruDefault: !_settings!.booruDefault));
                });
              },
              value: _settings!.booruDefault,
            ),
          )
        ]),
      ),
    );
  }
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/settings.dart' as schema_settings;
import 'package:gallery/src/widgets/system_gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../keybinds/keybinds.dart';
import '../schemas/settings.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final StreamSubscription<schema_settings.Settings?> _watcher;
  schema_settings.Settings? _settings = isar().settings.getSync(0);

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

  showDialog(String s) {
    Navigator.of(context).push(DialogRoute(
        context: context,
        builder: (context) => AlertDialog(
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.ok))
              ],
              content: Text(s),
            )));
  }

  @override
  Widget build(BuildContext context) {
    Map<SingleActivatorDescription, Null Function()> bindings = {
      SingleActivatorDescription(AppLocalizations.of(context)!.back,
          const SingleActivator(LogicalKeyboardKey.escape)): () {
        Navigator.pop(context);
      }
    };

    return CallbackShortcuts(
        bindings: {
          ...bindings,
          ...keybindDescription(context, describeKeys(bindings),
              AppLocalizations.of(context)!.settingsPageName)
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.settingsPageName)),
            body: gestureDeadZones(context,
                child: ListView(children: [
                  ListTile(
                    title: Text(
                        AppLocalizations.of(context)!.downloadDirectorySetting),
                    subtitle: Text(_settings!.path),
                    trailing: TextButton(
                      onPressed: () async {
                        await chooseDirectory(showDialog);
                      },
                      child: Text(AppLocalizations.of(context)!
                          .pickNewDownloadDirectory),
                    ),
                  ),
                  ListTile(
                    title: Text(
                        AppLocalizations.of(context)!.selectedBooruSetting),
                    trailing: DropdownButton<Booru>(
                      borderRadius: BorderRadius.circular(25),
                      underline: Container(),
                      value: _settings!.selectedBooru,
                      items: Booru.values
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.string),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != _settings!.selectedBooru) {
                          isar().writeTxnSync(() => isar()
                              .settings
                              .putSync(_settings!.copy(selectedBooru: value)));
                        }
                      },
                    ),
                  ),
                  ListTile(
                      title: Text(AppLocalizations.of(context)!
                          .imageDisplayQualitySetting),
                      leading: IconButton(
                        icon: const Icon(Icons.info_outlined),
                        onPressed: () {
                          Navigator.of(context).push(DialogRoute(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  content: Text(AppLocalizations.of(context)!
                                      .imageDisplayQualityInfo),
                                );
                              }));
                        },
                      ),
                      trailing: DropdownButton<DisplayQuality>(
                        underline: Container(),
                        borderRadius: BorderRadius.circular(25),
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
                    title: Text(AppLocalizations.of(context)!.listViewSetting),
                    leading: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(DialogRoute(
                              context: context,
                              builder: (context) => AlertDialog(
                                    content: Text(AppLocalizations.of(context)!
                                        .listViewInfo),
                                  )));
                        },
                        icon: const Icon(Icons.info_outline)),
                    subtitle:
                        Text(AppLocalizations.of(context)!.listViewSubtitle),
                    trailing: Switch(
                      value: _settings!.listViewBooru,
                      onChanged: (value) {
                        if (value != _settings!.listViewBooru) {
                          isar().writeTxnSync(() => isar()
                              .settings
                              .putSync(_settings!.copy(listViewBooru: value)));
                        }
                      },
                    ),
                  ),
                  ListTile(
                      title: Text(
                          AppLocalizations.of(context)!.nPerElementsSetting),
                      leading: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(DialogRoute(
                              context: context,
                              builder: (context) => AlertDialog(
                                  content: Text(AppLocalizations.of(context)!
                                      .nPerElementsInfo))));
                        },
                        icon: const Icon(Icons.info_outline),
                      ),
                      trailing: DropdownButton<int>(
                        underline: Container(),
                        borderRadius: BorderRadius.circular(25),
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
                                  isar().writeTxnSync(() => isar()
                                      .settings
                                      .putSync(_settings!
                                          .copy(picturesPerRow: value)));
                                }
                              },
                      )),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.safeModeSetting),
                    trailing: Switch(
                      value: _settings!.safeMode,
                      onChanged: (value) {
                        isar().writeTxnSync(() => isar().settings.putSync(
                            _settings!.copy(safeMode: !_settings!.safeMode)));
                      },
                    ),
                  ),
                  ListTile(
                    leading: IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) {
                              return const LicensePage();
                            },
                          ));
                        },
                        icon: const Icon(Icons.info_outline)),
                    title: Text(AppLocalizations.of(context)!.licenseSetting),
                    subtitle: const Text("GPL-2.0-only"),
                  )
                ])),
          ),
        ));
  }
}

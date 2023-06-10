// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/pages/server_settings.dart';
import 'package:gallery/src/schemas/settings.dart' as schema_settings;
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../schemas/settings.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final StreamSubscription<schema_settings.Settings?> _watcher;
  schema_settings.Settings? _settings = isar().settings.getSync(0);
  FocusNode focus = FocusNode();

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

    focus.dispose();

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
    return makeSkeletonInnerSettings(
        context,
        AppLocalizations.of(context)!.settingsPageName,
        focus,
        AppBar(title: Text(AppLocalizations.of(context)!.settingsPageName)),
        ListView(children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.downloadDirectorySetting),
            subtitle: Text(_settings!.path),
            trailing: TextButton(
              onPressed: () async {
                await chooseDirectory(showDialog);
              },
              child:
                  Text(AppLocalizations.of(context)!.pickNewDownloadDirectory),
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.selectedBooruSetting),
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

                  Navigator.popUntil(context, ModalRoute.withName("/booru"));

                  Navigator.pop(context);

                  Navigator.pushNamed(context, "/booru");
                }
              },
            ),
          ),
          ListTile(
              title: Text(
                  AppLocalizations.of(context)!.imageDisplayQualitySetting),
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
                            content: Text(
                                AppLocalizations.of(context)!.listViewInfo),
                          )));
                },
                icon: const Icon(Icons.info_outline)),
            subtitle: Text(AppLocalizations.of(context)!.listViewSubtitle),
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
              "Cell aspect ratio",
            ),
            trailing: DropdownButton<schema_settings.AspectRatio>(
              underline: Container(),
              borderRadius: BorderRadius.circular(25),
              value: _settings!.ratio,
              items: schema_settings.AspectRatio.values
                  .map((e) => DropdownMenuItem<schema_settings.AspectRatio>(
                        value: e,
                        child: Text(e.value.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != _settings!.ratio) {
                  isar().writeTxnSync(() =>
                      isar().settings.putSync(_settings!.copy(ratio: value)));
                }
              },
            ),
          ),
          ListTile(
              title: Text(AppLocalizations.of(context)!.nPerElementsSetting),
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
              trailing: DropdownButton<schema_settings.GridColumn>(
                underline: Container(),
                borderRadius: BorderRadius.circular(25),
                value: _settings!.picturesPerRow,
                items: schema_settings.GridColumn.values
                    .map((e) => DropdownMenuItem(
                        value: e, child: Text(e.number.toString())))
                    .toList(),
                onChanged: _settings!.listViewBooru
                    ? null
                    : (value) {
                        if (value != _settings!.picturesPerRow) {
                          isar().writeTxnSync(() => isar()
                              .settings
                              .putSync(_settings!.copy(picturesPerRow: value)));
                        }
                      },
              )),
          ListTile(
            title: Text(AppLocalizations.of(context)!.safeModeSetting),
            trailing: Switch(
              value: _settings!.safeMode,
              onChanged: (value) {
                isar().writeTxnSync(() => isar()
                    .settings
                    .putSync(_settings!.copy(safeMode: !_settings!.safeMode)));
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
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.serverSettingsPageName),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (context) {
              return const ServerSettingsPage();
            })),
          ),
          ListTile(
            title: Text("Hide directory names"),
            trailing: Switch(
              onChanged: (value) {
                isar().writeTxnSync(() => isar().settings.putSync(_settings!
                    .copy(
                        gallerySettings: _settings!.gallerySettings
                            .copy(hideDirectoryName: value))));
              },
              value: _settings!.gallerySettings.hideDirectoryName ?? false,
            ),
          ),
          ListTile(
            title: Text(
              "Directory cell aspect ratio",
            ),
            trailing: DropdownButton<schema_settings.AspectRatio>(
              underline: Container(),
              borderRadius: BorderRadius.circular(25),
              value: _settings!.gallerySettings.directoryAspectRatio,
              items: schema_settings.AspectRatio.values
                  .map((e) => DropdownMenuItem<schema_settings.AspectRatio>(
                        value: e,
                        child: Text(e.value.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != _settings!.gallerySettings.directoryAspectRatio) {
                  isar().writeTxnSync(() => isar().settings.putSync(_settings!
                      .copy(
                          gallerySettings: _settings!.gallerySettings
                              .copy(directoryAspectRatio: value))));
                }
              },
            ),
          ),
          ListTile(
              title: Text("Directory grid columns"),
              trailing: DropdownButton<schema_settings.GridColumn>(
                underline: Container(),
                borderRadius: BorderRadius.circular(25),
                value: _settings!.gallerySettings.directoryColumns,
                items: schema_settings.GridColumn.values
                    .map((e) => DropdownMenuItem(
                        value: e, child: Text(e.number.toString())))
                    .toList(),
                onChanged: (value) {
                  if (value != _settings!.gallerySettings.directoryColumns) {
                    isar().writeTxnSync(() => isar().settings.putSync(_settings!
                        .copy(
                            gallerySettings: _settings!.gallerySettings
                                .copy(directoryColumns: value))));
                  }
                },
              )),
          ListTile(
            title: Text("Hide file names"),
            trailing: Switch(
              onChanged: (value) {
                isar().writeTxnSync(() => isar().settings.putSync(_settings!
                    .copy(
                        gallerySettings: _settings!.gallerySettings
                            .copy(hideFileName: value))));
              },
              value: _settings!.gallerySettings.hideFileName ?? false,
            ),
          ),
          ListTile(
            title: Text(
              "Files cell aspect ratio",
            ),
            trailing: DropdownButton<schema_settings.AspectRatio>(
              underline: Container(),
              borderRadius: BorderRadius.circular(25),
              value: _settings!.gallerySettings.filesAspectRatio,
              items: schema_settings.AspectRatio.values
                  .map((e) => DropdownMenuItem<schema_settings.AspectRatio>(
                        value: e,
                        child: Text(e.value.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != _settings!.gallerySettings.filesAspectRatio) {
                  isar().writeTxnSync(() => isar().settings.putSync(_settings!
                      .copy(
                          gallerySettings: _settings!.gallerySettings
                              .copy(filesAspectRatio: value))));
                }
              },
            ),
          ),
          ListTile(
              title: Text("Files grid columns"),
              trailing: DropdownButton<schema_settings.GridColumn>(
                underline: Container(),
                borderRadius: BorderRadius.circular(25),
                value: _settings!.gallerySettings.filesColumns,
                items: schema_settings.GridColumn.values
                    .map((e) => DropdownMenuItem(
                        value: e, child: Text(e.number.toString())))
                    .toList(),
                onChanged: (value) {
                  if (value != _settings!.gallerySettings.filesColumns) {
                    isar().writeTxnSync(() => isar().settings.putSync(_settings!
                        .copy(
                            gallerySettings: _settings!.gallerySettings
                                .copy(filesColumns: value))));
                  }
                },
              )),
          ListTile(
            title: Text(AppLocalizations.of(context)!.savedTagsCount),
            enabled: false,
            subtitle: Text(BooruTags().savedTagsCount().toString()),
          )
        ]));
  }
}

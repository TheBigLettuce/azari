// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/pages/server_settings.dart';
import 'package:gallery/src/schemas/settings.dart' as schema_settings;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import '../schemas/settings.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final SkeletonState skeletonState = SkeletonState.settings();

  @override
  void dispose() {
    skeletonState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeletonSettings(
        context,
        AppLocalizations.of(context)!.settingsPageName,
        skeletonState,
        SettingsList(
          sliver: true,
          scaffoldKey: skeletonState.scaffoldKey,
        ));
  }
}

class SettingsList extends StatefulWidget {
  final bool sliver;
  final GlobalKey<ScaffoldState> scaffoldKey;
  const SettingsList({
    super.key,
    required this.sliver,
    required this.scaffoldKey,
  });

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
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

  bool extendListSubtitle = false;

  void _extend() => setState(() {
        extendListSubtitle = !extendListSubtitle;
      });

  @override
  void dispose() {
    _watcher.cancel();
    super.dispose();
  }

  List<Widget> makeList(BuildContext context, TextStyle titleStyle) => [
        ListTile(
          title: Text(AppLocalizations.of(context)!.serverSettingsPageName),
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (context) {
            return const ServerSettingsPage();
          })),
        ),
        settingsLabel("Booru", titleStyle),
        ListTile(
          title: Text(AppLocalizations.of(context)!.downloadDirectorySetting),
          subtitle: Text(
            _settings!.path,
            maxLines: extendListSubtitle ? null : 2,
          ),
          trailing: TextButton(
            onPressed: () async {
              await chooseDirectory(showDialog);
            },
            child: Text(AppLocalizations.of(context)!.pickNewDownloadDirectory),
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
            title:
                Text(AppLocalizations.of(context)!.imageDisplayQualitySetting),
            onTap: _extend,
            subtitle: Text(
              AppLocalizations.of(context)!.imageDisplayQualityInfo,
              maxLines: extendListSubtitle ? null : 2,
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
                  isar().writeTxnSync(() =>
                      isar().settings.putSync(_settings!.copy(quality: value)));
                }
              },
            )),
        ListTile(
          title: Text(AppLocalizations.of(context)!.listViewSetting),
          onTap: _extend,
          subtitle: Text(
            AppLocalizations.of(context)!.listViewInfo,
            maxLines: extendListSubtitle ? null : 2,
          ),
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
            onTap: _extend,
            subtitle: Text(
              AppLocalizations.of(context)!.nPerElementsInfo,
              maxLines: extendListSubtitle ? null : 2,
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
          title: Text("Auto refresh"),
          subtitle: Text("Refresh booru main grid on app open if it is stale.",
              maxLines: extendListSubtitle ? null : 2),
          onTap: _extend,
          trailing: Switch(
            onChanged: (value) {
              isar().writeTxnSync(() =>
                  isar().settings.putSync(_settings!.copy(autoRefresh: value)));
            },
            value: _settings!.autoRefresh,
          ),
        ),
        ListTile(
          title: Text("Auto refresh stale hours"),
          subtitle: Text(
            "After this time the grid becomes stale.",
            maxLines: extendListSubtitle ? null : 2,
          ),
          onTap: _extend,
          trailing: TextButton(
            onPressed: () {
              Navigator.push(
                  context,
                  DialogRoute(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Enter time in hours"),
                        content: TextField(
                          onSubmitted: (value) {
                            isar().writeTxnSync(() => isar().settings.putSync(
                                _settings!.copy(
                                    autoRefreshMicroseconds: int.parse(value)
                                        .hours
                                        .inMicroseconds)));
                            Navigator.pop(context);
                          },
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      );
                    },
                  ));
            },
            child: Text(
                Duration(microseconds: _settings!.autoRefreshMicroseconds)
                    .inHours
                    .toString()),
          ),
        ),
        settingsLabel("Directory", titleStyle),
        ListTile(
          title: Text("Hide directory names"),
          trailing: Switch(
            onChanged: (value) {
              isar().writeTxnSync(() => isar().settings.putSync(_settings!.copy(
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
        settingsLabel("Files", titleStyle),
        ListTile(
          title: Text("Hide file names"),
          trailing: Switch(
            onChanged: (value) {
              isar().writeTxnSync(() => isar().settings.putSync(_settings!.copy(
                  gallerySettings:
                      _settings!.gallerySettings.copy(hideFileName: value))));
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
        settingsLabel(AppLocalizations.of(context)!.licenseSetting, titleStyle),
        ListTile(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return const LicensePage();
              },
            ));
          },
          title: const Text("GPL-2.0-only"),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.savedTagsCount),
          enabled: false,
          onTap: _extend,
          subtitle: Text(BooruTags().savedTagsCount().toString()),
        )
      ];

  @override
  Widget build(BuildContext context) {
    var titleStyle = Theme.of(context)
        .textTheme
        .titleSmall!
        .copyWith(color: Theme.of(context).colorScheme.secondary);

    return widget.sliver
        ? SliverList.list(
            children: makeList(context, titleStyle),
          )
        : ListView(
            children: makeList(context, titleStyle),
          );
  }
}

Widget settingsLabel(String string, TextStyle style) => Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 18, right: 12, left: 16),
      child: Text(
        string,
        style: style,
      ),
    );

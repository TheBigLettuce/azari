// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/pages/blacklisted_directores.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import '../booru/interface.dart';
import '../schemas/settings.dart';
import '../schemas/settings.dart' as schema show AspectRatio;
import '../widgets/restart_widget.dart';
import '../widgets/settings_label.dart';

bool _isRestart = false;

bool get isRestart => _isRestart;
void restartOver() {
  _isRestart = false;
}

void selectBooru(BuildContext context, Settings settings, Booru value) {
  _isRestart = true;

  Settings.saveToDb(settings.copy(selectedBooru: value));

  RestartWidget.restartApp(context);
}

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
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
  late final StreamSubscription<Settings?> _watcher;

  Settings? _settings = Settings.fromDb();

  @override
  void initState() {
    super.initState();

    _watcher = settingsIsar()
        .settings
        .watchObject(0, fireImmediately: true)
        .listen((event) {
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

  void showDialog(String s) {
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
              title: const Text(
                "Error", // TODO: change
              ),
              content: Text(s),
            )));
  }

  static void _radioDialog<T>(BuildContext context, List<(T, String)> values,
      T groupValue, void Function(T? value) onChanged,
      {required String title}) {
    Navigator.push(
        context,
        DialogRoute(
          context: context,
          builder: (context) {
            return AlertDialog(
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Back", // TODO: change
                    ))
              ],
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: values
                    .map((e) => RadioListTile(
                        shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                        value: e.$1,
                        title: Text(e.$2),
                        groupValue: groupValue,
                        onChanged: (value) {
                          onChanged(value);
                          Navigator.pop(context);
                        }))
                    .toList(),
              ),
            );
          },
        ));
  }

  List<Widget> makeList(BuildContext context, TextStyle titleStyle) => [
        settingsLabel(AppLocalizations.of(context)!.booruLabel, titleStyle),
        ListTile(
          title: Text(AppLocalizations.of(context)!.downloadDirectorySetting),
          subtitle: Text(_settings!.path),
          onTap: () async {
            await chooseDirectory(showDialog);
          },
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.selectedBooruSetting),
          subtitle: Text(_settings!.selectedBooru.string),
          onTap: () => _radioDialog(
              context,
              Booru.values.map((e) => (e, e.string)).toList(),
              _settings!.selectedBooru, (value) {
            if (value != null && value != _settings!.selectedBooru) {
              selectBooru(context, _settings!, value);
            }
          }, title: AppLocalizations.of(context)!.selectedBooruSetting),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.imageDisplayQualitySetting),
          onTap: () => _radioDialog(
            context,
            DisplayQuality.values.map((e) => (e, e.string)).toList(),
            _settings!.quality,
            (value) => Settings.saveToDb(_settings!.copy(quality: value)),
            title: AppLocalizations.of(context)!.imageDisplayQualitySetting,
          ),
          subtitle: Text(_settings!.quality.string),
        ),
        SwitchListTile(
          value: _settings!.booruListView,
          onChanged: (value) =>
              Settings.saveToDb(_settings!.copy(booruListView: value)),
          title: Text(AppLocalizations.of(context)!.listViewSetting),
          subtitle: Text(AppLocalizations.of(context)!.listViewInfo),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.cellAspectRadio),
          subtitle: Text(_settings!.ratio.value.toString()),
          onTap: () => _radioDialog(
            context,
            schema.AspectRatio.values
                .map((e) => (e, e.value.toString()))
                .toList(),
            _settings!.ratio,
            (value) => Settings.saveToDb(_settings!.copy(ratio: value)),
            title: AppLocalizations.of(context)!.cellAspectRadio,
          ),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.nPerElementsSetting),
          onTap: () => _radioDialog(
            context,
            GridColumn.values.map((e) => (e, e.number.toString())).toList(),
            _settings!.picturesPerRow,
            (value) =>
                Settings.saveToDb(_settings!.copy(picturesPerRow: value)),
            title: AppLocalizations.of(context)!.nPerElementsSetting,
          ),
          subtitle: Text(_settings!.picturesPerRow.number.toString()),
        ),
        SwitchListTile(
          value: _settings!.safeMode,
          onChanged: (value) => Settings.saveToDb(
              _settings!.copy(safeMode: !_settings!.safeMode)),
          title: Text(AppLocalizations.of(context)!.safeModeSetting),
        ),
        SwitchListTile(
          value: _settings!.autoRefresh,
          onChanged: (value) =>
              Settings.saveToDb(_settings!.copy(autoRefresh: value)),
          title: Text(AppLocalizations.of(context)!.autoRefresh),
          subtitle: Text(AppLocalizations.of(context)!.autoRefreshSubtitle),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.autoRefreshHours),
          subtitle: Text(
              Duration(microseconds: _settings!.autoRefreshMicroseconds)
                  .inHours
                  .toString()),
          onTap: () {
            Navigator.push(
                context,
                DialogRoute(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(AppLocalizations.of(context)!.timeInHours),
                      content: TextField(
                        onSubmitted: (value) {
                          Settings.saveToDb(_settings!.copy(
                              autoRefreshMicroseconds:
                                  int.parse(value).hours.inMicroseconds));

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
        ),
        settingsLabel(AppLocalizations.of(context)!.dirLabel, titleStyle),
        SwitchListTile(
          value: _settings!.gallerySettings.hideDirectoryName,
          onChanged: (value) => Settings.saveToDb(_settings!.copy(
              gallerySettings:
                  _settings!.gallerySettings.copy(hideDirectoryName: value))),
          title: Text(AppLocalizations.of(context)!.dirHideNames),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.dirAspectRatio),
          subtitle: Text(
              _settings!.gallerySettings.directoryAspectRatio.value.toString()),
          onTap: () => _radioDialog(
            context,
            schema.AspectRatio.values
                .map((e) => (e, e.value.toString()))
                .toList(),
            _settings!.gallerySettings.directoryAspectRatio,
            (value) => Settings.saveToDb(
              _settings!.copy(
                  gallerySettings: _settings!.gallerySettings
                      .copy(directoryAspectRatio: value)),
            ),
            title: AppLocalizations.of(context)!.dirAspectRatio,
          ),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.dirGridColumns),
          subtitle: Text(
              _settings!.gallerySettings.directoryColumns.number.toString()),
          onTap: () => _radioDialog(
            context,
            GridColumn.values.map((e) => (e, e.number.toString())).toList(),
            _settings!.gallerySettings.directoryColumns,
            (value) => Settings.saveToDb(_settings!.copy(
                gallerySettings:
                    _settings!.gallerySettings.copy(directoryColumns: value))),
            title: AppLocalizations.of(context)!.dirGridColumns,
          ),
        ),
        settingsLabel(AppLocalizations.of(context)!.filesLabel, titleStyle),
        SwitchListTile(
          value: _settings!.gallerySettings.hideFileName,
          onChanged: (value) => Settings.saveToDb(_settings!.copy(
              gallerySettings:
                  _settings!.gallerySettings.copy(hideFileName: value))),
          title: Text(AppLocalizations.of(context)!.filesHideNames),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.filesAspectRatio),
          subtitle: Text(
              _settings!.gallerySettings.filesAspectRatio.value.toString()),
          onTap: () => _radioDialog(
            context,
            schema.AspectRatio.values
                .map((e) => (e, e.value.toString()))
                .toList(),
            _settings!.gallerySettings.filesAspectRatio,
            (value) => Settings.saveToDb(
              _settings!.copy(
                  gallerySettings:
                      _settings!.gallerySettings.copy(filesAspectRatio: value)),
            ),
            title: AppLocalizations.of(context)!.filesAspectRatio,
          ),
        ),
        ListTile(
            title: Text(AppLocalizations.of(context)!.filesGridColumns),
            subtitle:
                Text(_settings!.gallerySettings.filesColumns.number.toString()),
            onTap: () => _radioDialog(
                  context,
                  GridColumn.values
                      .map((e) => (e, e.number.toString()))
                      .toList(),
                  _settings!.gallerySettings.filesColumns,
                  (value) => Settings.saveToDb(
                    _settings!.copy(
                        gallerySettings: _settings!.gallerySettings
                            .copy(filesColumns: value)),
                  ),
                  title: AppLocalizations.of(context)!.filesGridColumns,
                )),
        SwitchListTile(
          value: _settings!.gallerySettings.filesListView,
          onChanged: (value) => Settings.saveToDb(
            _settings!.copy(
                gallerySettings:
                    _settings!.gallerySettings.copy(filesListView: value)),
          ),
          title: Text(AppLocalizations.of(context)!.filesListView),
        ),
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
        settingsLabel(AppLocalizations.of(context)!.metricsLabel, titleStyle),
        ListTile(
          title: Text(AppLocalizations.of(context)!.savedTagsCount),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_horiz_outlined),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                    child: TextButton(
                  onPressed: () {
                    PostTags().restore((err) {
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            duration: 1.minutes,
                            content: Text(AppLocalizations.of(context)!
                                .couldntRestoreBackup(err))));
                      } else {
                        setState(() {});
                      }
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.restore),
                )),
                PopupMenuItem(
                    child: TextButton(
                  onPressed: () {
                    PostTags().copy((err) {
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .couldntBackup(err))));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.backupSuccess)));
                      }
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.backup),
                )),
              ];
            },
          ),
          subtitle: Text(PostTags().savedTagsCount().toString()),
        ),
        if (Platform.isAndroid)
          ListTile(
            title: Text(
                AppLocalizations.of(context)!.blacklistedDirectoriesPageName),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlacklistedDirectories(),
                  ));
            },
          ),
        if (Platform.isAndroid)
          ListTile(
            title: Text(AppLocalizations.of(context)!.thumbnailsCSize),
            subtitle: Text(_calculateMBSize(thumbnailIsar().getSizeSync())),
            trailing: PopupMenuButton(
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                      child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                DialogRoute(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(AppLocalizations.of(context)!
                                          .areYouSure),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .no)),
                                        TextButton(
                                            onPressed: () {
                                              thumbnailIsar().writeTxnSync(() =>
                                                  thumbnailIsar().clearSync());

                                              setState(() {});
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .yes)),
                                      ],
                                    );
                                  },
                                ));
                          },
                          child: Text(
                              AppLocalizations.of(context)!.purgeThumbnails)))
                ];
              },
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ),
      ];

  String _calculateMBSize(int i) {
    if (i == 0) {
      return "0 MB";
    }

    return "${(i / (1000 * 1000)).toStringAsFixed(1)} MB";
  }

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

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
import 'package:gallery/main.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/pages/blacklisted_directores.dart';
import 'package:gallery/src/schemas/settings.dart' as schema_settings;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import '../booru/interface.dart';
import '../schemas/settings.dart';
import '../widgets/settings_label.dart';

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

  schema_settings.Settings? _settings = settingsIsar().settings.getSync(0);
  bool extendListSubtitle = false;

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
              content: Text(s),
            )));
  }

  void _extend() => setState(() {
        extendListSubtitle = !extendListSubtitle;
      });

  List<Widget> makeList(BuildContext context, TextStyle titleStyle) => [
        settingsLabel(AppLocalizations.of(context)!.booruLabel, titleStyle),
        ListTile(
          title: Text(AppLocalizations.of(context)!.downloadDirectorySetting),
          onTap: _extend,
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
                settingsIsar().writeTxnSync(() => settingsIsar()
                    .settings
                    .putSync(_settings!.copy(selectedBooru: value)));

                RestartWidget.restartApp(context);
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
                  settingsIsar().writeTxnSync(() => settingsIsar()
                      .settings
                      .putSync(_settings!.copy(quality: value)));
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
            value: _settings!.booruListView,
            onChanged: (value) {
              if (value != _settings!.booruListView) {
                settingsIsar().writeTxnSync(() => settingsIsar()
                    .settings
                    .putSync(_settings!.copy(booruListView: value)));
              }
            },
          ),
        ),
        ListTile(
          title: Text(
            AppLocalizations.of(context)!.cellAspectRadio,
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
                settingsIsar().writeTxnSync(() => settingsIsar()
                    .settings
                    .putSync(_settings!.copy(ratio: value)));
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
              onChanged: _settings!.booruListView
                  ? null
                  : (value) {
                      if (value != _settings!.picturesPerRow) {
                        settingsIsar().writeTxnSync(() => settingsIsar()
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
              settingsIsar().writeTxnSync(() => settingsIsar()
                  .settings
                  .putSync(_settings!.copy(safeMode: !_settings!.safeMode)));
            },
          ),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.autoRefresh),
          subtitle: Text(AppLocalizations.of(context)!.autoRefreshSubtitle,
              maxLines: extendListSubtitle ? null : 2),
          onTap: _extend,
          trailing: Switch(
            onChanged: (value) {
              settingsIsar().writeTxnSync(() => settingsIsar()
                  .settings
                  .putSync(_settings!.copy(autoRefresh: value)));
            },
            value: _settings!.autoRefresh,
          ),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.autoRefreshHours),
          subtitle: Text(
            AppLocalizations.of(context)!.autoRefreshHoursSubtitle,
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
                        title: Text(AppLocalizations.of(context)!.timeInHours),
                        content: TextField(
                          onSubmitted: (value) {
                            settingsIsar().writeTxnSync(() => settingsIsar()
                                .settings
                                .putSync(_settings!.copy(
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
        settingsLabel(AppLocalizations.of(context)!.dirLabel, titleStyle),
        ListTile(
          title: Text(AppLocalizations.of(context)!.dirHideNames),
          trailing: Switch(
            onChanged: (value) {
              settingsIsar().writeTxnSync(() => settingsIsar().settings.putSync(
                  _settings!.copy(
                      gallerySettings: _settings!.gallerySettings
                          .copy(hideDirectoryName: value))));
            },
            value: _settings!.gallerySettings.hideDirectoryName,
          ),
        ),
        ListTile(
          title: Text(
            AppLocalizations.of(context)!.dirAspectRatio,
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
                settingsIsar().writeTxnSync(() => settingsIsar()
                    .settings
                    .putSync(_settings!.copy(
                        gallerySettings: _settings!.gallerySettings
                            .copy(directoryAspectRatio: value))));
              }
            },
          ),
        ),
        ListTile(
            title: Text(AppLocalizations.of(context)!.dirGridColumns),
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
                  settingsIsar().writeTxnSync(() => settingsIsar()
                      .settings
                      .putSync(_settings!.copy(
                          gallerySettings: _settings!.gallerySettings
                              .copy(directoryColumns: value))));
                }
              },
            )),
        settingsLabel(AppLocalizations.of(context)!.filesLabel, titleStyle),
        ListTile(
          title: Text(AppLocalizations.of(context)!.filesHideNames),
          trailing: Switch(
            onChanged: (value) {
              settingsIsar().writeTxnSync(() => settingsIsar().settings.putSync(
                  _settings!.copy(
                      gallerySettings: _settings!.gallerySettings
                          .copy(hideFileName: value))));
            },
            value: _settings!.gallerySettings.hideFileName,
          ),
        ),
        ListTile(
          title: Text(
            AppLocalizations.of(context)!.filesAspectRatio,
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
                settingsIsar().writeTxnSync(() => settingsIsar()
                    .settings
                    .putSync(_settings!.copy(
                        gallerySettings: _settings!.gallerySettings
                            .copy(filesAspectRatio: value))));
              }
            },
          ),
        ),
        ListTile(
            title: Text(AppLocalizations.of(context)!.filesGridColumns),
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
                  settingsIsar().writeTxnSync(() => settingsIsar()
                      .settings
                      .putSync(_settings!.copy(
                          gallerySettings: _settings!.gallerySettings
                              .copy(filesColumns: value))));
                }
              },
            )),
        ListTile(
          title: Text(AppLocalizations.of(context)!.filesListView),
          trailing: Switch(
            value: _settings!.gallerySettings.filesListView,
            onChanged: (value) {
              if (value != _settings!.gallerySettings.filesListView) {
                settingsIsar().writeTxnSync(() => settingsIsar()
                    .settings
                    .putSync(_settings!.copy(
                        gallerySettings: _settings!.gallerySettings
                            .copy(filesListView: value))));
              }
            },
          ),
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
        // ListTile(
        //   title: const Text('Expensive "Same" algorithm'),
        //   subtitle: Text(
        //     "More accurate, at a cost of speed. Results persist.",
        //     maxLines: extendListSubtitle ? null : 2,
        //   ),
        //   onTap: _extend,
        //   trailing: Switch(
        //       value: _settings!.expensiveHash,
        //       onChanged: (value) {
        //         settingsIsar().writeTxnSync(() {
        //           settingsIsar()
        //               .settings
        //               .putSync(_settings!.copy(expensiveHash: value));
        //         });
        //       }),
        // ),
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
        ListTile(
          title: Text(AppLocalizations.of(context)!.saveTagsOnlyOnDownload),
          trailing: Switch(
              value: _settings!.saveTagsOnlyOnDownload,
              onChanged: (value) {
                settingsIsar().writeTxnSync(() => settingsIsar()
                    .settings
                    .putSync(_settings!.copy(saveTagsOnlyOnDownload: value)));
              }),
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

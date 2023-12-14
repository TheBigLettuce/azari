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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/plugs/platform_functions.dart';

import '../../db/initalize_db.dart';
import '../../db/post_tags.dart';
import '../../db/schemas/settings.dart';
import '../../interfaces/booru.dart';
import '../../widgets/radio_dialog.dart';
import '../../widgets/settings_label.dart';
import 'settings_widget.dart';

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

  Future<int>? thumbnailCount =
      Platform.isAndroid ? PlatformFunctions.thumbCacheSize() : null;

  @override
  void initState() {
    super.initState();

    _watcher = Settings.watch((s) {
      setState(() {
        _settings = s;
      });
    }, fire: false);
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
              title: Text(AppLocalizations.of(context)!.errorHalf),
              content: Text(s),
            )));
  }

  List<Widget> makeList(BuildContext context, TextStyle titleStyle) => [
        SettingsLabel(AppLocalizations.of(context)!.booruLabel, titleStyle),
        ListTile(
          title: Text(AppLocalizations.of(context)!.downloadDirectorySetting),
          subtitle: Text(_settings!.path),
          onTap: () async {
            await Settings.chooseDirectory(showDialog);
          },
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.selectedBooruSetting),
          subtitle: Text(_settings!.selectedBooru.string),
          onTap: () => radioDialog(
              context,
              Booru.values.map((e) => (e, e.string)),
              _settings!.selectedBooru, (value) {
            if (value != null && value != _settings!.selectedBooru) {
              selectBooru(context, _settings!, value);
            }
          }, title: AppLocalizations.of(context)!.selectedBooruSetting),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.imageDisplayQualitySetting),
          onTap: () => radioDialog(
            context,
            DisplayQuality.values.map((e) => (e, e.string)),
            _settings!.quality,
            (value) => _settings!.copy(quality: value).save(),
            title: AppLocalizations.of(context)!.imageDisplayQualitySetting,
          ),
          subtitle: Text(_settings!.quality.string),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.safeModeSetting),
          onTap: () => radioDialog(
              context,
              SafeMode.values.map((e) => (e, e.string)),
              _settings!.safeMode,
              (value) => _settings!.copy(safeMode: value).save(),
              title: AppLocalizations.of(context)!.safeModeSetting),
          subtitle: Text(_settings!.safeMode.string),
        ),
        SwitchListTile(
          value: _settings!.autoRefresh,
          onChanged: (value) => _settings!.copy(autoRefresh: value).save(),
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
                          _settings!
                              .copy(
                                  autoRefreshMicroseconds:
                                      int.parse(value).hours.inMicroseconds)
                              .save();

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
        SettingsLabel(AppLocalizations.of(context)!.licenseSetting, titleStyle),
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
        SettingsLabel(AppLocalizations.of(context)!.metricsLabel, titleStyle),
        ListTile(
          title: Text(AppLocalizations.of(context)!.savedTagsCount),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_horiz_outlined),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                    child: TextButton(
                  onPressed: () {
                    PostTags.g.restore((err) {
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
                    PostTags.g.copy((err) {
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
          subtitle: Text(PostTags.g.savedTagsCount().toString()),
        ),
        if (Platform.isAndroid)
          FutureBuilder(
              future: thumbnailCount,
              builder: (context, data) {
                return ListTile(
                  title: Text(AppLocalizations.of(context)!.thumbnailsCSize),
                  subtitle: data.hasData
                      ? Text(_calculateMBSize(data.data!))
                      : Text("Loading..."),
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
                                            title: Text(
                                                AppLocalizations.of(context)!
                                                    .areYouSure),
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .no)),
                                              TextButton(
                                                  onPressed: () {
                                                    Dbs.g.thumbnail!
                                                        .writeTxnSync(() => Dbs
                                                            .g.thumbnail!
                                                            .clearSync());

                                                    PlatformFunctions
                                                        .clearCachedThumbs();

                                                    thumbnailCount =
                                                        PlatformFunctions
                                                            .thumbCacheSize();

                                                    setState(() {});
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .yes)),
                                            ],
                                          );
                                        },
                                      ));
                                },
                                child: Text(AppLocalizations.of(context)!
                                    .purgeThumbnails)))
                      ];
                    },
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                );
              }),
      ];

  String _calculateMBSize(int i) {
    if (i == 0) {
      return "0 MB";
    }

    return "${(i / (1000 * 1000)).toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context)
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

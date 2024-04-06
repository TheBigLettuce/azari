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
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/db/schemas/gallery/pinned_thumbnail.dart';
import 'package:gallery/src/db/schemas/gallery/thumbnail.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/display_quality.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/widgets/menu_wrapper.dart';
import 'package:gallery/welcome_pages.dart';

import '../../../db/tags/post_tags.dart';
import '../../../db/schemas/settings/settings.dart';
import 'radio_dialog.dart';
import 'settings_label.dart';
import 'settings_widget.dart';

class SettingsList extends StatefulWidget {
  final bool sliver;

  const SettingsList({
    super.key,
    required this.sliver,
  });

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  late final StreamSubscription<Settings?> _watcher;
  late final StreamSubscription<MiscSettings?> _miscWatcher;

  Settings? _settings = Settings.fromDb();
  MiscSettings? _miscSettings = MiscSettings.current;

  Future<int>? thumbnailCount =
      Platform.isAndroid ? PlatformFunctions.thumbCacheSize() : null;

  Future<int>? pinnedThumbnailCount =
      Platform.isAndroid ? PlatformFunctions.thumbCacheSize(true) : null;

  @override
  void initState() {
    super.initState();

    _watcher = Settings.watch((s) {
      setState(() {
        _settings = s;
      });
    }, fire: false);

    _miscWatcher = MiscSettings.watch((s) {
      setState(() {
        _miscSettings = s;
      });
    });
  }

  @override
  void dispose() {
    _watcher.cancel();
    _miscWatcher.cancel();
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
              title: Text(AppLocalizations.of(context)!.error),
              content: Text(s),
            )));
  }

  List<Widget> makeList(BuildContext context, TextStyle titleStyle) => [
        SettingsLabel(AppLocalizations.of(context)!.booruLabel, titleStyle),
        MenuWrapper(
          title: _settings!.path.path,
          child: ListTile(
            title: Text(AppLocalizations.of(context)!.downloadDirectorySetting),
            subtitle: Text(_settings!.path.pathDisplay),
            onTap: () async {
              await Settings.chooseDirectory(
                showDialog,
                emptyResult: AppLocalizations.of(context)!.emptyResult,
                pickDirectory: AppLocalizations.of(context)!.pickDirectory,
                validDirectory:
                    AppLocalizations.of(context)!.chooseValidDirectory,
              );
            },
          ),
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
          title: Text(AppLocalizations.of(context)!.settingsTheme),
          onTap: () => radioDialog(
            context,
            ThemeType.values.map((e) => (e, e.translatedString(context))),
            _miscSettings!.themeType,
            (value) {
              if (value != null) {
                selectTheme(context, _miscSettings!, value);
              }
            },
            title: AppLocalizations.of(context)!.settingsTheme,
          ),
          subtitle: Text(_miscSettings!.themeType.translatedString(context)),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.imageDisplayQualitySetting),
          onTap: () => radioDialog(
            context,
            DisplayQuality.values.map((e) => (e, e.translatedString(context))),
            _settings!.quality,
            (value) => _settings!.copy(quality: value).save(),
            title: AppLocalizations.of(context)!.imageDisplayQualitySetting,
          ),
          subtitle: Text(_settings!.quality.translatedString(context)),
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
        SettingsLabel(AppLocalizations.of(context)!.miscLabel, titleStyle),
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
                      : Text(AppLocalizations.of(context)!.loadingPlaceholder),
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
                                                    Thumbnail.clear();

                                                    PlatformFunctions
                                                        .clearCachedThumbs();

                                                    thumbnailCount =
                                                        Future.value(0);

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
        if (Platform.isAndroid)
          FutureBuilder(
              future: pinnedThumbnailCount,
              builder: (context, data) {
                return ListTile(
                  title:
                      Text(AppLocalizations.of(context)!.pinnedThumbnailsSize),
                  subtitle: data.hasData
                      ? Text(_calculateMBSize(data.data!))
                      : Text(AppLocalizations.of(context)!.loadingPlaceholder),
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
                                                    PinnedThumbnail.clear();

                                                    PlatformFunctions
                                                        .clearCachedThumbs(
                                                            true);

                                                    thumbnailCount =
                                                        PlatformFunctions
                                                            .thumbCacheSize(
                                                                true);

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
        SwitchListTile(
          value: _miscSettings!.filesExtendedActions,
          onChanged: (value) => MiscSettings.setFilesExtendedActions(value),
          title: Text(AppLocalizations.of(context)!.extendedFilesGridActions),
        ),
        MenuWrapper(
          title: "GPL-2.0-only",
          child: ListTile(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const LicensePage();
                },
              ));
            },
            title: Text(AppLocalizations.of(context)!.licenseSetting),
            subtitle: const Text("GPL-2.0-only"),
          ),
        ),
        SwitchListTile(
          value: _miscSettings!.animeAlwaysLoadFromNet,
          onChanged: (value) => MiscSettings.setAnimeAlwaysLoadFromNet(value),
          title: Text(AppLocalizations.of(context)!.animeAlwaysOnline),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.openWelcomePageSetting),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return const WelcomePage(
                  doNotLaunchHome: true,
                );
              },
            ));
          },
        ),
        // SwitchListTile(
        //   title: Text(AppLocalizations.of(context)!.buddhaModeSetting),
        //   value: _settings!.buddhaMode,
        //   onChanged: (value) {
        //     themeChangeStart();

        //     _settings!.copy(buddhaMode: value).save();

        //     RestartWidget.restartApp(context);
        //   },
        // )
      ];

  String _calculateMBSize(int i) {
    if (i == 0) {
      return AppLocalizations.of(context)!.megabytes(0);
    }

    return AppLocalizations.of(context)!.megabytes((i / (1000 * 1000)));
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

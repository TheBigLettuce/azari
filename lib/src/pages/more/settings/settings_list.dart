// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/pages/more/settings/radio_dialog.dart";
import "package:gallery/src/pages/more/settings/settings_label.dart";
import "package:gallery/src/pages/more/settings/settings_widget.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";
import "package:gallery/welcome_pages.dart";

class SettingsList extends StatefulWidget {
  const SettingsList({
    super.key,
    required this.sliver,
    required this.db,
  });

  final bool sliver;

  final DbConn db;

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  late final StreamSubscription<SettingsData?> _watcher;
  late final StreamSubscription<MiscSettingsData?> _miscWatcher;

  DbConn get db => widget.db;

  SettingsData _settings = SettingsService.db().current;
  MiscSettingsData _miscSettings = MiscSettingsService.db().current;

  Future<int>? thumbnailCount =
      Platform.isAndroid ? PlatformFunctions.thumbCacheSize() : null;

  Future<int>? pinnedThumbnailCount =
      Platform.isAndroid ? PlatformFunctions.thumbCacheSize(true) : null;

  @override
  void initState() {
    super.initState();

    _watcher = _settings.s.watch((s) {
      setState(() {
        _settings = s!;
      });
    });

    _miscWatcher = _miscSettings.s.watch((s) {
      setState(() {
        _miscSettings = s!;
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
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
          title: Text(AppLocalizations.of(context)!.error),
          content: Text(s),
        ),
      ),
    );
  }

  List<Widget> makeList(
    BuildContext context,
    TextStyle titleStyle,
    AppLocalizations localizations,
  ) =>
      [
        SettingsLabel(localizations.booruLabel, titleStyle),
        MenuWrapper(
          title: _settings.path.path,
          child: ListTile(
            title: Text(localizations.downloadDirectorySetting),
            subtitle: Text(_settings.path.pathDisplay),
            onTap: () async {
              await SettingsService.db().chooseDirectory(
                showDialog,
                emptyResult: localizations.emptyResult,
                pickDirectory: localizations.pickDirectory,
                validDirectory: localizations.chooseValidDirectory,
              );
            },
          ),
        ),
        ListTile(
          title: Text(localizations.selectedBooruSetting),
          subtitle: Text(_settings.selectedBooru.string),
          onTap: () => radioDialog(
            context,
            Booru.values.map((e) => (e, e.string)),
            _settings.selectedBooru,
            (value) {
              if (value != null && value != _settings.selectedBooru) {
                selectBooru(context, _settings, value);
              }
            },
            title: localizations.selectedBooruSetting,
          ),
        ),
        ListTile(
          title: Text(localizations.settingsTheme),
          onTap: () => radioDialog(
            context,
            ThemeType.values.map((e) => (e, e.translatedString(context))),
            _miscSettings.themeType,
            (value) {
              if (value != null) {
                selectTheme(context, _miscSettings, value);
              }
            },
            title: localizations.settingsTheme,
          ),
          subtitle: Text(_miscSettings.themeType.translatedString(context)),
        ),
        ListTile(
          title: Text(localizations.imageDisplayQualitySetting),
          onTap: () => radioDialog(
            context,
            DisplayQuality.values.map((e) => (e, e.translatedString(context))),
            _settings.quality,
            (value) => _settings.copy(quality: value).save(),
            title: localizations.imageDisplayQualitySetting,
          ),
          subtitle: Text(_settings.quality.translatedString(context)),
        ),
        SettingsLabel(localizations.miscLabel, titleStyle),
        ListTile(
          title: Text(localizations.savedTagsCount),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_horiz_outlined),
            itemBuilder: (context) {
              return [
                PopupMenuItem<void>(
                  enabled: false,
                  child: TextButton(
                    onPressed: () {
                      PostTags.g.restore((err) {
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: 1.minutes,
                              content:
                                  Text(localizations.couldntRestoreBackup(err)),
                            ),
                          );
                        } else {
                          setState(() {});
                        }
                      });
                    },
                    child: Text(localizations.restore),
                  ),
                ),
                PopupMenuItem<void>(
                  enabled: false,
                  child: TextButton(
                    onPressed: () {
                      PostTags.g.copy((err) {
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(localizations.couldntBackup(err)),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(localizations.backupSuccess),
                            ),
                          );
                        }
                      });
                    },
                    child: Text(localizations.backup),
                  ),
                ),
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
                title: Text(localizations.thumbnailsCSize),
                subtitle: data.hasData
                    ? Text(_calculateMBSize(data.data!, localizations))
                    : Text(localizations.loadingPlaceholder),
                trailing: PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<void>(
                        enabled: false,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              DialogRoute<void>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(localizations.areYouSure),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(localizations.no),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          db.thumbnails.clear();

                                          PlatformFunctions.clearCachedThumbs();

                                          thumbnailCount = Future.value(0);

                                          setState(() {});
                                          Navigator.pop(context);
                                        },
                                        child: Text(localizations.yes),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                          child: Text(localizations.purgeThumbnails),
                        ),
                      ),
                    ];
                  },
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              );
            },
          ),
        if (Platform.isAndroid)
          FutureBuilder(
            future: pinnedThumbnailCount,
            builder: (context, data) {
              return ListTile(
                title: Text(localizations.pinnedThumbnailsSize),
                subtitle: data.hasData
                    ? Text(_calculateMBSize(data.data!, localizations))
                    : Text(localizations.loadingPlaceholder),
                trailing: PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<void>(
                        enabled: false,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              DialogRoute<void>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(localizations.areYouSure),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(localizations.no),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          db.pinnedThumbnails.clear();

                                          PlatformFunctions.clearCachedThumbs(
                                            true,
                                          );

                                          thumbnailCount =
                                              PlatformFunctions.thumbCacheSize(
                                            true,
                                          );

                                          setState(() {});
                                          Navigator.pop(context);
                                        },
                                        child: Text(localizations.yes),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                          child: Text(localizations.purgeThumbnails),
                        ),
                      ),
                    ];
                  },
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              );
            },
          ),
        SwitchListTile(
          value: _miscSettings.filesExtendedActions,
          onChanged: (value) => MiscSettingsService.db()
              .current
              .copy(filesExtendedActions: value)
              .save(),
          title: Text(localizations.extendedFilesGridActions),
        ),
        MenuWrapper(
          title: "GPL-2.0-only",
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) {
                    return const LicensePage();
                  },
                ),
              );
            },
            title: Text(localizations.licenseSetting),
            subtitle: const Text("GPL-2.0-only"),
          ),
        ),
        SwitchListTile(
          value: _miscSettings.animeAlwaysLoadFromNet,
          onChanged: (value) => MiscSettingsService.db()
              .current
              .copy(animeAlwaysLoadFromNet: value)
              .save(),
          title: Text(localizations.animeAlwaysOnline),
        ),
        ListTile(
          title: Text(localizations.openWelcomePageSetting),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return const WelcomePage(
                    doNotLaunchHome: true,
                  );
                },
              ),
            );
          },
        ),
      ];

  String _calculateMBSize(int i, AppLocalizations localizations) {
    if (i == 0) {
      return localizations.megabytes(0);
    }

    return localizations.megabytes(i / (1000 * 1000));
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context)
        .textTheme
        .titleSmall!
        .copyWith(color: Theme.of(context).colorScheme.secondary);

    final localizations = AppLocalizations.of(context)!;

    return widget.sliver
        ? SliverList.list(
            children: makeList(context, titleStyle, localizations),
          )
        : ListView(
            children: makeList(context, titleStyle, localizations),
          );
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/booru_api.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/pages/more/settings/radio_dialog.dart";
import "package:gallery/src/pages/more/settings/settings_label.dart";
import "package:gallery/src/pages/more/settings/settings_widget.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
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

  Future<int> thumbnailCount = GalleryManagementApi.current().thumbs.size();

  Future<int> pinnedThumbnailCount =
      GalleryManagementApi.current().thumbs.size(true);

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
    final l10n = AppLocalizations.of(context)!;

    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(l10n.ok),
            ),
          ],
          title: Text(l10n.error),
          content: Text(s),
        ),
      ),
    );
  }

  List<Widget> makeList(
    BuildContext context,
    TextStyle titleStyle,
    AppLocalizations l10n,
  ) =>
      [
        SettingsLabel(l10n.booruLabel, titleStyle),
        MenuWrapper(
          title: _settings.path.path,
          child: ListTile(
            title: Text(l10n.downloadDirectorySetting),
            subtitle: Text(_settings.path.pathDisplay),
            onTap: () async {
              await SettingsService.db().chooseDirectory(showDialog, l10n);
            },
          ),
        ),
        ListTile(
          title: Text(l10n.selectedBooruSetting),
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
            title: l10n.selectedBooruSetting,
          ),
        ),
        ListTile(
          title: Text(l10n.settingsTheme),
          onTap: () => radioDialog(
            context,
            ThemeType.values.map((e) => (e, e.translatedString(l10n))),
            _miscSettings.themeType,
            (value) {
              if (value != null) {
                selectTheme(context, _miscSettings, value);
              }
            },
            title: l10n.settingsTheme,
          ),
          subtitle: Text(_miscSettings.themeType.translatedString(l10n)),
        ),
        ListTile(
          title: Text(l10n.imageDisplayQualitySetting),
          onTap: () => radioDialog(
            context,
            DisplayQuality.values.map((e) => (e, e.translatedString(l10n))),
            _settings.quality,
            (value) => _settings.copy(quality: value).save(),
            title: l10n.imageDisplayQualitySetting,
          ),
          subtitle: Text(_settings.quality.translatedString(l10n)),
        ),
        SettingsLabel(l10n.miscLabel, titleStyle),
        FutureBuilder(
          future: thumbnailCount,
          builder: (context, data) {
            return ListTile(
              title: Text(l10n.thumbnailsCSize),
              subtitle: data.hasData
                  ? Text(_calculateMBSize(data.data!, l10n))
                  : Text(l10n.loadingPlaceholder),
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
                                  title: Text(l10n.areYouSure),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(l10n.no),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        db.thumbnails.clear();

                                        GalleryManagementApi.current()
                                            .thumbs
                                            .clear();

                                        thumbnailCount = Future.value(0);

                                        setState(() {});
                                        Navigator.pop(context);
                                      },
                                      child: Text(l10n.yes),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                        child: Text(l10n.purgeThumbnails),
                      ),
                    ),
                  ];
                },
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            );
          },
        ),
        FutureBuilder(
          future: pinnedThumbnailCount,
          builder: (context, data) {
            return ListTile(
              title: Text(l10n.pinnedThumbnailsSize),
              subtitle: data.hasData
                  ? Text(_calculateMBSize(data.data!, l10n))
                  : Text(l10n.loadingPlaceholder),
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
                                  title: Text(l10n.areYouSure),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(l10n.no),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        db.pinnedThumbnails.clear();

                                        GalleryManagementApi.current()
                                            .thumbs
                                            .clear(true);

                                        thumbnailCount =
                                            GalleryManagementApi.current()
                                                .thumbs
                                                .size(true);

                                        setState(() {});
                                        Navigator.pop(context);
                                      },
                                      child: Text(l10n.yes),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                        child: Text(l10n.purgeThumbnails),
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
          title: Text(l10n.extendedFilesGridActions),
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
            title: Text(l10n.licenseSetting),
            subtitle: const Text("GPL-2.0-only"),
          ),
        ),
        SwitchListTile(
          title: Text(l10n.animeAlwaysOnline),
          value: _miscSettings.animeAlwaysLoadFromNet,
          onChanged: (value) =>
              _miscSettings.copy(animeAlwaysLoadFromNet: value).save(),
        ),
        SwitchListTile(
          title: Text(l10n.showAnimeManga),
          value: _settings.showAnimeMangaPages,
          onChanged: (value) =>
              _settings.copy(showAnimeMangaPages: value).save(),
        ),
        SwitchListTile(
          title: Text(l10n.extraSafeModeFilters),
          subtitle: Text(
            l10n.blacklistsTags(BooruAPI.additionalSafetyTags.keys.join(", ")),
          ),
          value: _settings.extraSafeFilters,
          onChanged: (value) => _settings.copy(extraSafeFilters: value).save(),
        ),
        ListTile(
          title: Text(l10n.openWelcomePageSetting),
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
    final theme = Theme.of(context);

    final titleStyle = theme.textTheme.titleSmall!
        .copyWith(color: theme.colorScheme.secondary);

    final l10n = AppLocalizations.of(context)!;

    return widget.sliver
        ? SliverList.list(
            children: makeList(context, titleStyle, l10n),
          )
        : ListView(
            children: makeList(context, titleStyle, l10n),
          );
  }
}

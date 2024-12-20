// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/display_quality.dart";
import "package:azari/src/pages/other/settings/radio_dialog.dart";
import "package:azari/src/pages/other/settings/settings_page.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/menu_wrapper.dart";
import "package:azari/welcome_pages.dart";
import "package:flutter/material.dart";

class SettingsList extends StatefulWidget {
  const SettingsList({
    super.key,
    required this.db,
  });

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

  Future<int> thumbnailCount = GalleryApi().thumbs.size();

  Future<int> pinnedThumbnailCount = GalleryApi().thumbs.size(true);

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
    final l10n = context.l10n();

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

  String _calculateMBSize(int i, AppLocalizations localizations) {
    if (i == 0) {
      return localizations.megabytes(0);
    }

    return localizations.megabytes(i / (1000 * 1000));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // final titleStyle = theme.textTheme.titleSmall!
    //     .copyWith(color: theme.colorScheme.secondary);

    final l10n = context.l10n();

    final list = <Widget>[
      _SettingsGroup(
        children: [
          ListTile(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            tileColor: theme.colorScheme.surfaceContainerHigh,
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
            tileColor: theme.colorScheme.surfaceContainerHigh,
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
          SwitchListTile(
            title: Text(l10n.extraSafeModeFilters),
            tileColor: theme.colorScheme.surfaceContainerHigh,
            subtitle: Text(
              l10n.blacklistsTags(
                BooruAPI.additionalSafetyTags.keys.join(", "),
              ),
            ),
            value: _settings.extraSafeFilters,
            onChanged: (value) =>
                _settings.copy(extraSafeFilters: value).save(),
          ),
          // SwitchListTile(
          //   shape: const RoundedRectangleBorder(
          //     borderRadius: BorderRadius.only(
          //       bottomLeft: Radius.circular(25),
          //       bottomRight: Radius.circular(25),
          //     ),
          //   ),
          //   tileColor: theme.colorScheme.surfaceContainerHigh,
          //   value: _settings.sampleThumbnails,
          //   onChanged: (value) => SettingsService.db()
          //       .current
          //       .copy(sampleThumbnails: value)
          //       .save(),
          //   title: const Text("Show samples as thumbnail"), // TODO: change
          // ),
        ],
      ),
      _SettingsGroup(
        children: [
          MenuWrapper(
            title: _settings.path.path,
            child: ListTile(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              tileColor: theme.colorScheme.surfaceContainerHigh,
              title: Text(l10n.downloadDirectorySetting),
              subtitle: Text(_settings.path.pathDisplay),
              onTap: () async {
                await SettingsService.db().chooseDirectory(showDialog, l10n);
              },
            ),
          ),
          ListTile(
            title: Text(l10n.settingsTheme),
            tileColor: theme.colorScheme.surfaceContainerHigh,
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
          SwitchListTile(
            tileColor: theme.colorScheme.surfaceContainerHigh,
            value: _miscSettings.filesExtendedActions,
            onChanged: (value) => MiscSettingsService.db()
                .current
                .copy(filesExtendedActions: value)
                .save(),
            title: Text(l10n.extendedFilesGridActions),
          ),
          FutureBuilder(
            future: thumbnailCount,
            builder: (context, data) {
              return ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                tileColor: theme.colorScheme.surfaceContainerHigh,
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

                                          GalleryApi().thumbs.clear();

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
        ],
      ),
      MenuWrapper(
        title: "GPL-2.0-only",
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onTap: () => const LicensePage().open(context),
          title: Text(l10n.licenseSetting),
          subtitle: const Text("GPL-2.0-only"),
        ),
      ),
      ListTile(
        title: Text(l10n.openWelcomePageSetting),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: () => WelcomePage.open(
          context,
          popBackOnEnd: true,
        ),
      ),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList.list(
        children: list,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    // super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        child: ListBody(
          children: children,
        ),
      ),
    );
  }
}

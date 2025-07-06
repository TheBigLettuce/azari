// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/settings/radio_dialog.dart";
import "package:azari/src/ui/material/pages/settings/settings_page.dart";
import "package:azari/src/ui/material/widgets/menu_wrapper.dart";
import "package:flutter/material.dart";

class SettingsList extends StatefulWidget {
  const SettingsList({super.key});

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> with SettingsWatcherMixin {
  late Future<int> thumbnailCount;

  late Future<int> pinnedThumbnailCount;

  @override
  void initState() {
    super.initState();

    thumbnailCount = ThumbsApi.safe()?.size() ?? Future.value(0);
    pinnedThumbnailCount = ThumbsApi.safe()?.size(true) ?? Future.value(0);
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

  Future<void> onTap() async =>
      await chooseDirectoryCallback(showDialog, context.l10n());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            subtitle: Text(settings.selectedBooru.string),
            onTap: () => radioDialog(
              context,
              Booru.values.map((e) => (e, e.string)),
              settings.selectedBooru,
              (value) {
                if (value != null && value != settings.selectedBooru) {
                  selectBooru(context, settings, value);
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
              settings.quality,
              (value) => settings.copy(quality: value).save(),
              title: l10n.imageDisplayQualitySetting,
            ),
            subtitle: Text(settings.quality.translatedString(l10n)),
          ),
          SwitchListTile(
            title: Text(l10n.extraSafeModeFilters),
            tileColor: theme.colorScheme.surfaceContainerHigh,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            subtitle: Text(
              l10n.blacklistsTags(
                BooruAPI.additionalSafetyTags.keys.join(", "),
              ),
            ),
            value: settings.extraSafeFilters,
            onChanged: (value) => settings.copy(extraSafeFilters: value).save(),
          ),
        ],
      ),
      _SettingsGroup(
        children: [
          MenuWrapper(
            title: settings.path.path,
            child: ListTile(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              tileColor: theme.colorScheme.surfaceContainerHigh,
              title: Text(l10n.downloadDirectorySetting),
              subtitle: Text(settings.path.pathDisplay),
              onTap: GalleryService.available ? onTap : null,
            ),
          ),
          ListTile(
            title: Text(l10n.settingsTheme),
            tileColor: theme.colorScheme.surfaceContainerHigh,
            onTap: () => radioDialog(
              context,
              ThemeType.values.map((e) => (e, e.translatedString(l10n))),
              settings.themeType,
              (value) {
                if (value != null) {
                  selectTheme(context, settings, value);
                }
              },
              title: l10n.settingsTheme,
            ),
            subtitle: Text(settings.themeType.translatedString(l10n)),
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
                  enabled:
                      ThumbnailService.available && GalleryService.available,
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<void>(
                        enabled: false,
                        child: TextButton(
                          onPressed: () {
                            void clear() {
                              const ThumbnailService().clear();
                              const ThumbsApi().clear();

                              thumbnailCount = Future.value(0);

                              setState(() {});
                              Navigator.pop(context);
                            }

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
                                        onPressed:
                                            ThumbnailService.available &&
                                                GalleryService.available
                                            ? clear
                                            : null,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onTap: () => const LicensePage().open(context),
          title: Text(l10n.licenseSetting),
          subtitle: const Text("GPL-2.0-only"),
        ),
      ),
      SwitchListTile(
        title: const Text("Exception alerts"), // TODO: change
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        value: settings.exceptionAlerts,
        onChanged: (_) =>
            settings.copy(exceptionAlerts: !settings.exceptionAlerts).save(),
      ),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList.list(children: list),
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
        child: ListBody(children: children),
      ),
    );
  }
}

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
            trailing: IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: AccountsService.available
                  ? () => AccountsDialog.open(context)
                  : null,
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

class AccountsDialog extends StatefulWidget {
  const AccountsDialog({super.key});

  static void open(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push<void>(
        DialogRoute(
          context: context,
          useSafeArea: false,
          builder: (context) => const AccountsDialog(),
        ),
      );

  @override
  State<AccountsDialog> createState() => _AccountsDialogState();
}

class _AccountsDialogState extends State<AccountsDialog>
    with AccountsServiceWatcherMixin {
  bool danbooruExpanded = false;
  bool gelbooruExpanded = false;

  bool get gelbooruSetUp =>
      accountsData.gelbooruApiKey.isNotEmpty &&
      accountsData.gelbooruUserId.isNotEmpty;

  bool get danbooruSetUp =>
      accountsData.danbooruApiKey.isNotEmpty &&
      accountsData.danbooruUsername.isNotEmpty;

  void _flipDanbooru() {
    danbooruExpanded = !danbooruExpanded;
    gelbooruExpanded = false;
    setState(() {});
  }

  void _flipGellboru() {
    gelbooruExpanded = !gelbooruExpanded;
    danbooruExpanded = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      constraints: const BoxConstraints(maxWidth: 380),
      child: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 12) +
              const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Accounts", style: theme.textTheme.headlineSmall),
              const Padding(padding: EdgeInsets.only(top: 10)),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCrossFade(
                      firstCurve: Easing.standard,
                      secondCurve: Easing.standard,
                      sizeCurve: Easing.standard,
                      duration: Durations.medium3,
                      reverseDuration: Durations.medium1,
                      firstChild: ListBody(
                        children: [
                          ListTile(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25),
                              ),
                            ),
                            tileColor: theme.colorScheme.surfaceContainerLow,
                            title: Text(Booru.danbooru.string),
                            subtitle: danbooruSetUp
                                ? Text(
                                    "${accountsData.danbooruUsername}:"
                                        .padRight(
                                          accountsData.danbooruApiKey.length +
                                              accountsData
                                                  .danbooruUsername
                                                  .length +
                                              1,
                                          "*",
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const Text("Tap to set up"),
                            trailing: danbooruSetUp
                                ? const Icon(Icons.mode_edit_rounded)
                                : const Icon(Icons.login_rounded),
                            onTap: () {
                              setState(() {
                                danbooruExpanded = true;
                                gelbooruExpanded = false;
                              });
                            },
                          ),
                        ],
                      ),
                      secondChild: DanbooruAccountSettings(
                        returnBack: _flipDanbooru,
                      ),
                      crossFadeState: danbooruExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                    ),
                    AnimatedCrossFade(
                      firstCurve: Easing.standard,
                      secondCurve: Easing.standard,
                      sizeCurve: Easing.standard,
                      duration: Durations.medium3,
                      reverseDuration: Durations.medium1,
                      firstChild: ListBody(
                        children: [
                          ListTile(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(25),
                                bottomRight: Radius.circular(25),
                              ),
                            ),
                            tileColor: theme.colorScheme.surfaceContainerLow,
                            title: Text(Booru.gelbooru.string),
                            subtitle: gelbooruSetUp
                                ? Text(
                                    "${accountsData.gelbooruUserId}:".padRight(
                                      accountsData.gelbooruApiKey.length +
                                          accountsData.gelbooruUserId.length +
                                          1,
                                      "*",
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const Text("Tap to set up"),
                            trailing: gelbooruSetUp
                                ? const Icon(Icons.mode_edit_rounded)
                                : const Icon(Icons.login_rounded),
                            onTap: () {
                              setState(() {
                                gelbooruExpanded = true;
                                danbooruExpanded = false;
                              });
                            },
                          ),
                        ],
                      ),
                      secondChild: GelbooruAccountSettings(
                        returnBack: _flipGellboru,
                      ),
                      crossFadeState: gelbooruExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DanbooruAccountSettings extends StatefulWidget {
  const DanbooruAccountSettings({super.key, required this.returnBack});

  final VoidCallback returnBack;

  @override
  State<DanbooruAccountSettings> createState() =>
      _DanbooruAccountSettingsState();
}

class _DanbooruAccountSettingsState extends State<DanbooruAccountSettings>
    with AccountsServiceWatcherMixin {
  @override
  Widget build(BuildContext context) {
    return _Form(
      loginHint: "Username",
      apiKeyHint: "Api key",
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      dividerAtTop: false,
      returnBack: widget.returnBack,
      onSubmit: (login, apiKey) => accountsData
          .copy(danbooruUsername: login, danbooruApiKey: apiKey)
          .maybeSave(),
      loginData: accountsData.danbooruUsername,
      apiKeyData: accountsData.danbooruApiKey,
    );
  }
}

class GelbooruAccountSettings extends StatefulWidget {
  const GelbooruAccountSettings({super.key, required this.returnBack});

  final VoidCallback returnBack;

  @override
  State<GelbooruAccountSettings> createState() =>
      _GelbooruAccountSettingsState();
}

class _GelbooruAccountSettingsState extends State<GelbooruAccountSettings>
    with AccountsServiceWatcherMixin {
  @override
  Widget build(BuildContext context) {
    return _Form(
      loginHint: "Login ID",
      apiKeyHint: "Api key",
      returnBack: widget.returnBack,
      dividerAtTop: true,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(25),
        bottomRight: Radius.circular(25),
      ),
      onSubmit: (login, apiKey) => accountsData
          .copy(gelbooruUserId: login, gelbooruApiKey: apiKey)
          .maybeSave(),
      loginData: accountsData.gelbooruUserId,
      apiKeyData: accountsData.gelbooruApiKey,
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({
    super.key,
    required this.loginHint,
    required this.apiKeyHint,
    required this.onSubmit,
    required this.returnBack,
    required this.borderRadius,
    required this.dividerAtTop,
    required this.loginData,
    required this.apiKeyData,
  });

  final bool dividerAtTop;

  final String loginHint;
  final String apiKeyHint;

  final String loginData;
  final String apiKeyData;

  final BorderRadiusGeometry borderRadius;

  final VoidCallback returnBack;
  final void Function(String login, String apiKey) onSubmit;

  @override
  State<_Form> createState() => __FormState();
}

class __FormState extends State<_Form> {
  late final loginController = TextEditingController(text: widget.loginData);
  late final apiKeyController = TextEditingController(text: widget.apiKeyData);

  bool get canCommit =>
      loginController.text.isNotEmpty && apiKeyController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();

    loginController.addListener(_listener);
    apiKeyController.addListener(_listener);
  }

  @override
  void dispose() {
    loginController.dispose();
    apiKeyController.dispose();

    super.dispose();
  }

  void _listener() {
    setState(() {});
  }

  void _commit() {
    widget.onSubmit(loginController.text.trim(), apiKeyController.text.trim());
    widget.returnBack();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: widget.borderRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.dividerAtTop)
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Divider(indent: 0, endIndent: 0, height: 0, thickness: 1),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: loginController,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.mode_edit_outline, size: 18),
                          hint: Text(widget.loginHint),
                          suffix: IconButton(
                            onPressed: loginController.clear,
                            icon: const Icon(Icons.clear_rounded),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      TextField(
                        controller: apiKeyController,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.mode_edit_outline, size: 18),
                          hint: Text(widget.apiKeyHint),
                          suffix: IconButton(
                            onPressed: apiKeyController.clear,
                            icon: const Icon(Icons.clear_rounded),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12) +
                const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: widget.returnBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text("Back"),
                ),
                if (loginController.text.isEmpty &&
                    apiKeyController.text.isEmpty &&
                    widget.apiKeyData.isNotEmpty &&
                    widget.loginData.isNotEmpty)
                  TextButton.icon(
                    onPressed: _commit,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text("Remove"),
                  )
                else
                  TextButton.icon(
                    onPressed: canCommit ? _commit : null,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text("Save"),
                  ),
              ],
            ),
          ),
          if (!widget.dividerAtTop)
            const Divider(indent: 0, endIndent: 0, height: 0),
        ],
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
        child: ListBody(children: children),
      ),
    );
  }
}

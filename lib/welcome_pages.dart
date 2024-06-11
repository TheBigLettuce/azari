// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/display_quality.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/pages/home.dart";
import "package:gallery/src/pages/more/settings/radio_dialog.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:permission_handler/permission_handler.dart";

class AndroidPermissionsPage extends StatefulWidget {
  const AndroidPermissionsPage({
    super.key,
    required this.doNotLaunchHome,
  });
  final bool doNotLaunchHome;

  @override
  State<AndroidPermissionsPage> createState() => _AndroidPermissionsPageState();
}

class _AndroidPermissionsPageState extends State<AndroidPermissionsPage> {
  bool photoAndVideos = false;
  bool notifications = false;
  bool mediaLocation = false;
  bool storage = false;
  bool manageMedia = false;

  bool? manageMediaSupported;

  static const _androidApi = AndroidApiFunctions();

  @override
  void initState() {
    super.initState();

    _androidApi.manageMediaSupported().then(
          (value) => setState(() {
            manageMediaSupported = value;

            if (value) {
              _androidApi.manageMediaStatus().then(
                    (value) => setState(() {
                      manageMedia = value;
                    }),
                  );
            }
          }),
        );

    Permission.notification.status.then((value) async {
      notifications = value.isGranted;
      photoAndVideos = await Permission.photos.isGranted &&
          await Permission.videos.isGranted;
      mediaLocation = await Permission.accessMediaLocation.isGranted;
      storage = await Permission.storage.isGranted;
      await Permission.storage.request();

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _WrapPadding(
      title: l10n.welcomePermissions,
      explanation: l10n.welcomePermissionsExplanation,
      body: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ButtonWithPadding(
                icon: const Icon(Icons.photo),
                onPressed: () async {
                  final resultPhotos = await Permission.photos.request();
                  final resultVideos = await Permission.videos.request();

                  setState(() {
                    photoAndVideos =
                        resultVideos.isGranted && resultPhotos.isGranted;
                  });
                },
                label: l10n.permissionsPhotosVideos,
                variant: photoAndVideos
                    ? ButtonVariant.selected
                    : ButtonVariant.normal,
              ),
              _ButtonWithPadding(
                icon: const Icon(Icons.folder_copy),
                onPressed: () async {
                  final result = await Permission.accessMediaLocation.request();

                  setState(() {
                    mediaLocation = result.isGranted;
                  });
                },
                label: l10n.permissionsMediaLocation,
                variant: mediaLocation
                    ? ButtonVariant.selected
                    : ButtonVariant.secondary,
              ),
              if (manageMediaSupported != null && manageMediaSupported!)
                _ButtonWithPadding(
                  icon: const Icon(Icons.perm_media),
                  onPressed: () async {
                    final result = await _androidApi.requestManageMedia();

                    setState(() {
                      manageMedia = result;
                    });
                  },
                  label: l10n.permissionsManageMedia,
                  variant: manageMedia
                      ? ButtonVariant.selected
                      : ButtonVariant.secondary,
                ),
              _ButtonWithPadding(
                icon: const Icon(Icons.notifications_rounded),
                onPressed: () async {
                  final result = await Permission.notification.request();

                  setState(() {
                    notifications = result.isGranted;
                  });
                },
                label: l10n.permissionsNotifications,
                variant: notifications
                    ? ButtonVariant.selected
                    : ButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
      buttons: [
        FilledButton.icon(
          icon: const Icon(Icons.navigate_next_rounded),
          onPressed: !photoAndVideos
              ? null
              : () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return CongratulationPage(
                          doNotLaunchHome: widget.doNotLaunchHome,
                        );
                      },
                    ),
                  );
                },
          label: Text(l10n.welcomeNextLabel),
        ),
      ],
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, this.doNotLaunchHome = false});
  final bool doNotLaunchHome;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _WrapPadding(
      title: l10n.welcomeWelcome,
      addCenteredIcon: true,
      body: Text(
        l10n.welcomeSomeSettings,
        style: theme.textTheme.bodyLarge,
      ),
      buttons: [
        FilledButton.icon(
          icon: const Icon(Icons.navigate_next_rounded),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return InitalSettings(
                    doNotLaunchHome: widget.doNotLaunchHome,
                  );
                },
              ),
            );
          },
          label: Text(l10n.welcomeNextLabel),
        ),
      ],
    );
  }
}

class CongratulationPage extends StatelessWidget {
  const CongratulationPage({
    super.key,
    required this.doNotLaunchHome,
  });
  final bool doNotLaunchHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Stack(
      children: [
        _WrapPadding(
          title: l10n.welcomeDone,
          addCenteredIcon: true,
          body: Center(
            child: Text(
              l10n.welcomeFinishBody,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          buttons: [
            FilledButton.icon(
              label: Text(l10n.welcomeFinishLabel),
              icon: const Icon(Icons.check_rounded),
              onPressed: () {
                SettingsService.db()
                    .current
                    .copy(showWelcomePage: false)
                    .save();

                if (doNotLaunchHome) {
                  Navigator.pop(context);

                  return;
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return const Home();
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class InitalSettings extends StatefulWidget {
  const InitalSettings({
    super.key,
    required this.doNotLaunchHome,
  });
  final bool doNotLaunchHome;

  @override
  State<InitalSettings> createState() => _InitalSettingsState();
}

class _InitalSettingsState extends State<InitalSettings> {
  late final StreamSubscription<void> watcher;
  SettingsData settings = SettingsService.db().current;

  String? error;

  @override
  void initState() {
    super.initState();

    watcher = settings.s.watch((s) {
      settings = s!;

      error = null;

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  void _nextPage() {
    Navigator.pushReplacement(
      context,
      PlatformApi.current().requiresPermissions
          ? MaterialPageRoute<void>(
              builder: (context) {
                return AndroidPermissionsPage(
                  doNotLaunchHome: widget.doNotLaunchHome,
                );
              },
            )
          : MaterialPageRoute<void>(
              builder: (context) {
                return CongratulationPage(
                  doNotLaunchHome: widget.doNotLaunchHome,
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _WrapPadding(
      title: l10n.welcomeInitalSettings,
      explanation: l10n.welcomeInitalSettingsExplanation,
      body: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.tonalIcon(
              icon: settings.path.isNotEmpty
                  ? const Icon(Icons.check_rounded)
                  : const Icon(Icons.folder),
              onPressed: () {
                settings.s.chooseDirectory(
                  (e) {
                    error = e;

                    setState(() {});
                  },
                  l10n,
                );
              },
              label: Text(
                settings.path.isEmpty
                    ? l10n.downloadDirectorySetting
                    : settings.path.pathDisplay,
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            _ButtonWithPadding(
              icon: const Icon(Icons.image_rounded),
              onPressed: () {
                radioDialog(
                  context,
                  Booru.values.map((e) => (e, e.string)),
                  settings.selectedBooru,
                  (value) {
                    settings.copy(selectedBooru: value).save();
                  },
                  title: l10n.booruLabel,
                );
              },
              label: "${l10n.booruLabel}: ${settings.selectedBooru.string}",
              variant: ButtonVariant.secondary,
            ),
            _ButtonWithPadding(
              icon: const Icon(Icons.settings_display),
              onPressed: () {
                radioDialog(
                  context,
                  DisplayQuality.values
                      .map((e) => (e, e.translatedString(l10n))),
                  settings.quality,
                  (value) {
                    settings.copy(quality: value).save();
                  },
                  title: l10n.imageDisplayQualitySetting,
                );
              },
              label:
                  "${l10n.imageDisplayQualitySetting}: ${settings.quality.translatedString(l10n)}",
              variant: ButtonVariant.secondary,
            ),
            _ButtonWithPadding(
              icon: const Icon(Icons.eighteen_up_rating_rounded),
              onPressed: () {
                radioDialog(
                  context,
                  SafeMode.values.map((e) => (e, e.translatedString(l10n))),
                  settings.safeMode,
                  (value) {
                    settings.copy(safeMode: value).save();
                  },
                  title: l10n.safeModeSetting,
                );
              },
              label:
                  "${l10n.safeModeSetting}: ${settings.safeMode.translatedString(l10n)}",
              variant: ButtonVariant.secondary,
            ),
            _ButtonWithPadding(
              icon: const Icon(Icons.no_adult_content_rounded),
              onPressed: () => settings
                  .copy(extraSafeFilters: !settings.extraSafeFilters)
                  .save(),
              label: l10n.extraSafeModeFilters,
              variant: settings.extraSafeFilters
                  ? ButtonVariant.selectedUnselectable
                  : ButtonVariant.secondary,
            ),
          ],
        ),
      ),
      buttons: [
        FilledButton.icon(
          icon: const Icon(Icons.navigate_next_rounded),
          onPressed: settings.path.isEmpty ? null : _nextPage,
          label: Text(l10n.welcomeNextLabel),
        ),
      ],
    );
  }
}

class _WrapPadding extends StatelessWidget {
  const _WrapPadding({
    required this.body,
    required this.buttons,
    required this.title,
    this.explanation,
    this.addCenteredIcon = false,
  });
  final List<Widget> buttons;
  final String title;
  final Widget body;
  final String? explanation;
  final bool addCenteredIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: navBarStyleForTheme(theme, transparent: false),
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.only(
            top: 80,
            bottom: 40 + MediaQuery.viewPaddingOf(context).bottom,
            left: 40,
            right: 40,
          ),
          child: Stack(
            children: [
              if (addCenteredIcon)
                Center(
                  child: Transform.rotate(
                    angle: 0.4363323,
                    child: Icon(
                      const IconData(0x963F),
                      size: 78,
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      applyTextScaling: true,
                    ),
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineLarge,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: body,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (explanation == null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: buttons,
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.secondary.withOpacity(0.8),
                          applyTextScaling: true,
                        ),
                        const Padding(padding: EdgeInsets.only(left: 8)),
                        Expanded(
                          child: Text(
                            explanation!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.only(left: 8)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: buttons,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ButtonVariant {
  selected,
  selectedUnselectable,
  secondary,
  normal;
}

class _ButtonWithPadding extends StatelessWidget {
  const _ButtonWithPadding({
    required this.icon,
    required this.onPressed,
    required this.label,
    required this.variant,
  });
  final Icon icon;
  final void Function() onPressed;
  final String label;
  final ButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: variant == ButtonVariant.secondary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: Text(label),
            )
          : FilledButton.tonalIcon(
              icon: const Icon(Icons.check_rounded),
              onPressed: variant == ButtonVariant.selected ? null : onPressed,
              label: Text(label),
            ),
    );
  }
}

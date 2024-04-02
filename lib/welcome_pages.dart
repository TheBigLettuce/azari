// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/display_quality.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/pages/home.dart';
import 'package:gallery/src/pages/more/settings/radio_dialog.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AndroidPermissionsPage extends StatefulWidget {
  final bool doNotLaunchHome;

  const AndroidPermissionsPage({
    super.key,
    required this.doNotLaunchHome,
  });

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

  @override
  void initState() {
    super.initState();

    PlatformFunctions.manageMediaSupported().then(
      (value) => setState(() {
        manageMediaSupported = value;

        if (value) {
          PlatformFunctions.manageMediaStatus().then(
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
    return _WrapPadding(
      title: AppLocalizations.of(context)!.welcomePermissions,
      explanation: AppLocalizations.of(context)!.welcomePermissionsExplanation,
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
                label: AppLocalizations.of(context)!.permissionsPhotosVideos,
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
                label: AppLocalizations.of(context)!.permissionsMediaLocation,
                variant: mediaLocation
                    ? ButtonVariant.selected
                    : ButtonVariant.secondary,
              ),
              if (manageMediaSupported != null && manageMediaSupported!)
                _ButtonWithPadding(
                  icon: const Icon(Icons.perm_media),
                  onPressed: () async {
                    final result = await PlatformFunctions.requestManageMedia();

                    setState(() {
                      manageMedia = result;
                    });
                  },
                  label: AppLocalizations.of(context)!.permissionsManageMedia,
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
                label: AppLocalizations.of(context)!.permissionsNotifications,
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
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (context) {
                      return CongratulationPage(
                        doNotLaunchHome: widget.doNotLaunchHome,
                      );
                    },
                  ));
                },
          label: Text(AppLocalizations.of(context)!.welcomeNextLabel),
        ),
      ],
    );
  }
}

class WelcomePage extends StatefulWidget {
  final bool doNotLaunchHome;

  const WelcomePage({super.key, this.doNotLaunchHome = false});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      changeSystemUiOverlay(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _WrapPadding(
      title: AppLocalizations.of(context)!.welcomeWelcome,
      addCenteredIcon: true,
      body: Text(
        AppLocalizations.of(context)!.welcomeSomeSettings,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      buttons: [
        FilledButton.icon(
          icon: const Icon(Icons.navigate_next_rounded),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) {
                return InitalSettings(
                  doNotLaunchHome: widget.doNotLaunchHome,
                );
              },
            ));
          },
          label: Text(AppLocalizations.of(context)!.welcomeNextLabel),
        )
      ],
    );
  }
}

class CongratulationPage extends StatelessWidget {
  final bool doNotLaunchHome;

  const CongratulationPage({
    super.key,
    required this.doNotLaunchHome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        _WrapPadding(
          title: AppLocalizations.of(context)!.welcomeDone,
          addCenteredIcon: true,
          body: Center(
            child: Text(
              AppLocalizations.of(context)!.welcomeFinishBody,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          buttons: [
            FilledButton.icon(
              label: Text(AppLocalizations.of(context)!.welcomeFinishLabel),
              icon: const Icon(Icons.check_rounded),
              onPressed: () {
                Settings.fromDb().copy(showWelcomePage: false).save();

                if (doNotLaunchHome) {
                  Navigator.pop(context);

                  return;
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const Home();
                    },
                  ),
                );
              },
            )
          ],
        )
      ],
    );
  }
}

class InitalSettings extends StatefulWidget {
  final bool doNotLaunchHome;

  const InitalSettings({
    super.key,
    required this.doNotLaunchHome,
  });

  @override
  State<InitalSettings> createState() => _InitalSettingsState();
}

class _InitalSettingsState extends State<InitalSettings> {
  late final StreamSubscription<void> watcher;
  Settings settings = Settings.fromDb();

  String? error;

  @override
  void initState() {
    super.initState();

    watcher = Settings.watch((s) {
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
    if (Platform.isAndroid) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) {
          return AndroidPermissionsPage(
            doNotLaunchHome: widget.doNotLaunchHome,
          );
        },
      ));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) {
          return CongratulationPage(
            doNotLaunchHome: widget.doNotLaunchHome,
          );
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _WrapPadding(
      title: AppLocalizations.of(context)!.welcomeInitalSettings,
      explanation:
          AppLocalizations.of(context)!.welcomeInitalSettingsExplanation,
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
                Settings.chooseDirectory(
                  (e) {
                    error = e;

                    setState(() {});
                  },
                  emptyResult: AppLocalizations.of(context)!.emptyResult,
                  pickDirectory: AppLocalizations.of(context)!.pickDirectory,
                  validDirectory:
                      AppLocalizations.of(context)!.chooseValidDirectory,
                );
              },
              label: Text(settings.path.isEmpty
                  ? AppLocalizations.of(context)!.downloadDirectorySetting
                  : settings.path.pathDisplay),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
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
                  title: AppLocalizations.of(context)!.booruLabel,
                );
              },
              label:
                  "${AppLocalizations.of(context)!.booruLabel}: ${settings.selectedBooru.string}",
              variant: ButtonVariant.secondary,
            ),
            _ButtonWithPadding(
              icon: const Icon(Icons.settings_display),
              onPressed: () {
                radioDialog(
                  context,
                  DisplayQuality.values
                      .map((e) => (e, e.translatedString(context))),
                  settings.quality,
                  (value) {
                    settings.copy(quality: value).save();
                  },
                  title:
                      AppLocalizations.of(context)!.imageDisplayQualitySetting,
                );
              },
              label:
                  "${AppLocalizations.of(context)!.imageDisplayQualitySetting}: ${settings.quality.translatedString(context)}",
              variant: ButtonVariant.secondary,
            ),
            _ButtonWithPadding(
              icon: const Icon(Icons.eighteen_up_rating_rounded),
              onPressed: () {
                radioDialog(
                  context,
                  SafeMode.values.map((e) => (e, e.translatedString(context))),
                  settings.safeMode,
                  (value) {
                    settings.copy(safeMode: value).save();
                  },
                  title: AppLocalizations.of(context)!.safeModeSetting,
                );
              },
              label:
                  "${AppLocalizations.of(context)!.safeModeSetting}: ${settings.safeMode.translatedString(context)}",
              variant: ButtonVariant.secondary,
            )
          ],
        ),
      ),
      buttons: [
        FilledButton.icon(
          icon: const Icon(Icons.navigate_next_rounded),
          onPressed: settings.path.isEmpty ? null : _nextPage,
          label: Text(AppLocalizations.of(context)!.welcomeNextLabel),
        )
      ],
    );
  }
}

class _WrapPadding extends StatelessWidget {
  final List<Widget> buttons;
  final String title;
  final Widget body;
  final String? explanation;
  final bool addCenteredIcon;

  const _WrapPadding({
    super.key,
    required this.body,
    required this.buttons,
    required this.title,
    this.explanation,
    this.addCenteredIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
            top: 80,
            bottom: 40 + MediaQuery.viewPaddingOf(context).bottom,
            left: 40,
            right: 40),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                explanation == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: buttons,
                      )
                    : Row(
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
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.8),
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
                      )
              ],
            )
          ],
        ),
      ),
    );
  }
}

enum ButtonVariant {
  selected,
  secondary,
  normal;
}

class _ButtonWithPadding extends StatelessWidget {
  final double padding;
  final Icon icon;
  final void Function() onPressed;
  final String label;
  final ButtonVariant variant;

  const _ButtonWithPadding({
    super.key,
    this.padding = 8,
    required this.icon,
    required this.onPressed,
    required this.label,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: variant == ButtonVariant.secondary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: Text(label),
            )
          : FilledButton.tonalIcon(
              icon: variant == ButtonVariant.selected
                  ? const Icon(Icons.check_rounded)
                  : icon,
              onPressed: variant == ButtonVariant.selected ? null : onPressed,
              label: Text(label),
            ),
    );
  }
}

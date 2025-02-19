// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/build_theme.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/display_quality.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/pages/other/settings/radio_dialog.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({
    super.key,
    required this.onEnd,
    required this.permissions,
    required this.settingsService,
  });

  final List<PermissionController> permissions;

  final ContextCallback? onEnd;

  final SettingsService settingsService;

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  final _handlers = <Object, (bool, bool)>{};

  @override
  void initState() {
    super.initState();

    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    for (final e in widget.permissions) {
      final enabled = await e.enabled;

      if (enabled) {
        _handlers[e.token] = (await e.granted, true);
      } else {
        _handlers[e.token] = (false, false);
      }
    }

    if (context.mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return _WrapPadding(
      title: l10n.welcomePermissions,
      // explanation: l10n.welcomePermissionsExplanation,
      body: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.permissions.map(
              (e) {
                final (label, icon) = e.translatedNameIcon(l10n);
                final handle = _handlers[e.token]; //(granted, enabled)

                return _ButtonWithPadding(
                  icon: Icon(icon),
                  onPressed: handle == null || !handle.$2
                      ? null
                      : () async {
                          _handlers[e.token] = (await e.request(), true);

                          if (context.mounted) {
                            setState(() {});
                          }
                        },
                  label: label,
                  variant: handle?.$1 ?? false
                      ? ButtonVariant.selected
                      : ButtonVariant.normal,
                );
              },
            ).toList(),
          ),
        ),
      ),
      buttons: [
        FilledButton.icon(
          icon: const Icon(Icons.navigate_next_rounded),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return CongratulationPage(
                    onEnd: widget.onEnd,
                    settingsService: widget.settingsService,
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
  const WelcomePage({
    super.key,
    required this.settingsService,
    required this.galleryService,
    this.onEnd,
  });

  final ContextCallback? onEnd;

  final GalleryService? galleryService;
  final SettingsService settingsService;

  static void open(
    BuildContext context, {
    bool popBackOnEnd = false,
    required SettingsService settingsService,
    required GalleryService? galleryService,
  }) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) {
            return WelcomePage(
              galleryService: galleryService,
              settingsService: settingsService,
              onEnd: popBackOnEnd
                  ? (context) {
                      Navigator.pop(context);
                    }
                  : null,
            );
          },
        ),
      );

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
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
                    onEnd: widget.onEnd,
                    settingsService: widget.settingsService,
                    galleryService: widget.galleryService,
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
    required this.onEnd,
    required this.settingsService,
  });

  final ContextCallback? onEnd;
  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
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
                settingsService.current.copy(showWelcomePage: false).save();

                onEnd?.call(context);
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
    required this.onEnd,
    required this.settingsService,
    required this.galleryService,
  });

  final ContextCallback? onEnd;

  final GalleryService? galleryService;
  final SettingsService settingsService;

  @override
  State<InitalSettings> createState() => _InitalSettingsState();
}

class _InitalSettingsState extends State<InitalSettings>
    with SettingsWatcherMixin {
  GalleryService? get galleryService => widget.galleryService;

  @override
  SettingsService get settingsService => widget.settingsService;

  String? error;

  @override
  void onNewSettings(SettingsData newSettings) {
    error = null;
  }

  void _nextPage() {
    final permissions = PlatformApi().requiredPermissions;

    Navigator.pushReplacement(
      context,
      permissions.isNotEmpty
          ? MaterialPageRoute<void>(
              builder: (context) {
                return PermissionsPage(
                  permissions: permissions,
                  settingsService: settingsService,
                  onEnd: widget.onEnd,
                );
              },
            )
          : MaterialPageRoute<void>(
              builder: (context) {
                return CongratulationPage(
                  onEnd: widget.onEnd,
                  settingsService: settingsService,
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
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
              onPressed: galleryService != null
                  ? () {
                      SettingsService.chooseDirectory(
                        (e) {
                          error = e;

                          setState(() {});
                        },
                        l10n,
                        galleryServices: galleryService!,
                      );
                    }
                  : null,
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
          onPressed: settings.path.isNotEmpty || galleryService == null
              ? _nextPage
              : null,
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

  final bool addCenteredIcon;

  final String title;
  final String? explanation;

  final List<Widget> buttons;
  final Widget body;

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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
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
                          color: theme.colorScheme.secondary
                              .withValues(alpha: 0.8),
                          applyTextScaling: true,
                        ),
                        const Padding(padding: EdgeInsets.only(left: 8)),
                        Expanded(
                          child: Text(
                            explanation!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
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

  final String label;
  final Icon icon;

  final ButtonVariant variant;

  final VoidCallback? onPressed;

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
              icon: variant == ButtonVariant.selected
                  ? const Icon(Icons.check_rounded)
                  : icon,
              onPressed: variant == ButtonVariant.selected ? null : onPressed,
              label: Text(label),
            ),
    );
  }
}

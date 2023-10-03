// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/pages/settings/settings_widget.dart';

import '../../../interfaces/booru.dart';
import '../../settings_label.dart';
import 'azari_icon.dart';
import 'destinations.dart';
import 'select_destination.dart';

Widget? makeDrawer(BuildContext context, int selectedIndex,
    {void Function(int route, void Function() original)? overrideChooseRoute,
    Booru? overrideBooru}) {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return null;
  }
  final currentBooru = Settings.fromDb().selectedBooru;

  return NavigationDrawer(
    selectedIndex: selectedIndex,
    onDestinationSelected: (value) {
      if (selectedIndex == kBooruGridDrawerIndex) {
        Navigator.pop(context);
      }

      if (overrideChooseRoute != null) {
        overrideChooseRoute(
            value, () => selectDestination(context, selectedIndex, value));
      } else {
        selectDestination(context, selectedIndex, value);
      }
    },
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: ListTile(
          title: azariIcon(context,
                  color: Theme.of(context).colorScheme.primary)
              .animate(
                  effects: [ShakeEffect(duration: 700.milliseconds, hz: 6)]),
          style: ListTileStyle.drawer,
        ),
      ),
      ...destinations(context, overrideBooru: overrideBooru),
      NavigationDrawerDestination(
          icon: const Icon(Icons.settings),
          label: Text(AppLocalizations.of(context)!.settingsLabel)),
      const Divider(),
      settingsLabel(
          "Switch booru",
          Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(color: Theme.of(context).colorScheme.secondary)),
      ...Booru.values
          .where((element) => element != currentBooru)
          .map((e) => ListTile(
                textColor: Theme.of(context).colorScheme.primary,
                iconColor: Theme.of(context).colorScheme.primary,
                title: Text(
                  e.string,
                  style: const TextStyle(letterSpacing: 1.5),
                ),
                onTap: () => selectBooru(context, Settings.fromDb(), e),
                leading: const Icon(Icons.arrow_forward_rounded),
                style: ListTileStyle.drawer,
              ))
    ],
  );
}

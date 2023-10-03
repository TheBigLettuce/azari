// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../pages/settings/settings_widget.dart';
import '../skeletons/drawer/destinations.dart';
import '../skeletons/drawer/select_destination.dart';
import 'single_activator_description.dart';

Map<SingleActivatorDescription, Null Function()> digitAndSettings(
    BuildContext context, int from, GlobalKey<ScaffoldState> key) {
  return {
    SingleActivatorDescription(AppLocalizations.of(context)!.goBooruGrid,
        const SingleActivator(LogicalKeyboardKey.digit1, control: true)): () {
      if (from != kBooruGridDrawerIndex) {
        selectDestination(context, from, kBooruGridDrawerIndex);
      }
    },
    const SingleActivatorDescription(
        "Go to the favorites", // TODO: change
        SingleActivator(LogicalKeyboardKey.digit2, control: true)): () {
      selectDestination(context, from, kFavoritesDrawerIndex);
    },
    SingleActivatorDescription(AppLocalizations.of(context)!.goGallery,
        const SingleActivator(LogicalKeyboardKey.digit3, control: true)): () {
      selectDestination(context, from, kGalleryDrawerIndex);
    },
    SingleActivatorDescription(AppLocalizations.of(context)!.goTags,
        const SingleActivator(LogicalKeyboardKey.digit4, control: true)): () {
      selectDestination(context, from, kTagsDrawerIndex);
    },
    SingleActivatorDescription(AppLocalizations.of(context)!.goDownloads,
        const SingleActivator(LogicalKeyboardKey.digit5, control: true)): () {
      selectDestination(context, from, kDownloadsDrawerIndex);
    },
    SingleActivatorDescription(AppLocalizations.of(context)!.goSettings,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true)): () {
      if (Platform.isAndroid || Platform.isIOS) {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const SettingsWidget();
        }));
        return;
      } else {
        key.currentState?.openEndDrawer();
      }
    }
  };
}

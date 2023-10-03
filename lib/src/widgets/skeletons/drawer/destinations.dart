// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/download_file.dart';

import '../../../db/initalize_db.dart';
import '../../../db/schemas/settings.dart';
import '../../../interfaces/booru.dart';

const int kBooruGridDrawerIndex = 0;
const int kGalleryDrawerIndex = 1;
const int kFavoritesDrawerIndex = 2;
const int kBookmarksDrawerIndex = 3;
const int kTagsDrawerIndex = 4;
const int kDownloadsDrawerIndex = 5;
const int kSettingsDrawerIndex = 6;
const int kComeFromRandom = -1;

List<NavigationDrawerDestination> destinations(BuildContext context,
    {Booru? overrideBooru}) {
  final primaryColor = Theme.of(context).colorScheme.primary;

  return [
    NavigationDrawerDestination(
      icon: const Icon(Icons.image),
      selectedIcon: Icon(
        Icons.image,
        color: primaryColor,
      ),
      label:
          Text(overrideBooru?.string ?? Settings.fromDb().selectedBooru.string),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Icons.photo_album),
      selectedIcon: Icon(
        Icons.photo_album,
        color: primaryColor,
      ),
      label: Text(AppLocalizations.of(context)!.galleryLabel),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Icons.favorite),
      selectedIcon: Icon(
        Icons.favorite,
        color: primaryColor,
      ),
      label: Text(AppLocalizations.of(context)!.favoritesLabel),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Icons.bookmark),
      selectedIcon: Icon(
        Icons.bookmark,
        color: primaryColor,
      ),
      label: const Text("Bookmarks"), // TODO: change
    ),
    NavigationDrawerDestination(
      icon: const Icon(Icons.tag),
      selectedIcon: Icon(
        Icons.tag,
        color: primaryColor,
      ),
      label: Text(AppLocalizations.of(context)!.tagsLabel),
    ),
    NavigationDrawerDestination(
        icon: Dbs.g.main.downloadFiles.countSync() != 0
            ? const Badge(
                child: Icon(Icons.download),
              )
            : const Icon(Icons.download),
        selectedIcon: Icon(
          Icons.download,
          color: primaryColor,
        ),
        label: Text(AppLocalizations.of(context)!.downloadsLabel)),
  ];
}

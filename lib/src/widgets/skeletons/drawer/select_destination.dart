// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../../../db/schemas/settings.dart';
import '../../../db/state_restoration.dart';
import '../../../pages/bookmarks.dart';
import '../../../pages/downloads.dart';
import '../../../pages/favorites.dart';
import '../../../pages/gallery/directories.dart';
import '../../../pages/settings/settings_widget.dart';
import '../../../pages/tags.dart';
import 'destinations.dart';

void selectDestination(BuildContext context, int from, int selectedIndex) =>
    switch (selectedIndex) {
      kBooruGridDrawerIndex => {
          if (from != kBooruGridDrawerIndex)
            {
              Navigator.popUntil(context, ModalRoute.withName("/senitel")),
              Navigator.pop(context),
            }
        },
      kBookmarksDrawerIndex => {
          if (from == kBooruGridDrawerIndex)
            {
              Navigator.pushNamed(context, "/senitel"),
            },
          if (from != kBookmarksDrawerIndex)
            {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Bookmarks(),
                  ),
                  ModalRoute.withName("/senitel")),
            }
        },
      kTagsDrawerIndex => {
          if (from == kBooruGridDrawerIndex)
            {
              Navigator.pushNamed(context, "/senitel"),
            },
          if (from != kTagsDrawerIndex)
            {
              if (from == kGalleryDrawerIndex)
                {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TagsPage(
                          tagManager: TagManager.fromEnum(
                              Settings.fromDb().selectedBooru, false),
                          popSenitel: false,
                          fromGallery: true,
                        ),
                      ))
                }
              else
                {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TagsPage(
                          tagManager: TagManager.fromEnum(
                              Settings.fromDb().selectedBooru, false),
                          popSenitel: true,
                          fromGallery: false,
                        ),
                      ),
                      ModalRoute.withName("/senitel"))
                }
            }
        },
      kDownloadsDrawerIndex => {
          if (from == kBooruGridDrawerIndex || from == kComeFromRandom)
            {
              Navigator.pushNamed(context, "/senitel"),
            },
          if (from != kDownloadsDrawerIndex)
            {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Downloads(),
                  ),
                  ModalRoute.withName("/senitel"))
            }
        },
      kFavoritesDrawerIndex => {
          if (from == kBooruGridDrawerIndex)
            {
              Navigator.pushNamed(context, "/senitel"),
            },
          if (from != kFavoritesDrawerIndex)
            {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(),
                  ),
                  ModalRoute.withName("/senitel"))
            }
        },
      kSettingsDrawerIndex => {
          if (from != kSettingsDrawerIndex)
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SettingsWidget()))
        },
      kGalleryDrawerIndex => {
          if (from == kBooruGridDrawerIndex)
            {
              Navigator.pushNamed(context, "/senitel"),
            },
          if (from != kGalleryDrawerIndex)
            {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GalleryDirectories()),
                  ModalRoute.withName("/senitel"))
            }
        },
      int() => throw "unknown value"
    };

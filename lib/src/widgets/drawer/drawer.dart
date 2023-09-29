// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/state_restoration.dart';
import 'package:gallery/src/gallery/android_api/android_directories.dart';
import 'package:gallery/src/pages/bookmarks.dart';
import 'package:gallery/src/pages/favorites.dart';
import 'package:gallery/src/pages/tags.dart';
import 'package:gallery/src/pages/downloads.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/widgets/settings_label.dart';
import '../../booru/interface.dart';
import '../../db/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/pages/settings.dart';

const int kBooruGridDrawerIndex = 0;
const int kGalleryDrawerIndex = 1;
const int kFavoritesDrawerIndex = 2;
const int kBookmarksDrawerIndex = 3;
const int kTagsDrawerIndex = 4;
const int kDownloadsDrawerIndex = 5;
const int kSettingsDrawerIndex = 6;
const int kComeFromRandom = -1;

Widget azariIcon(BuildContext context, {Color? color}) => Icon(
      const IconData(0x963F),
      color: color,
    ); // 阿

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
          if (Platform.isAndroid)
            {
              if (from == kBooruGridDrawerIndex)
                {
                  Navigator.pushNamed(context, "/senitel"),
                },
              if (from != kGalleryDrawerIndex)
                {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AndroidDirectories()),
                      ModalRoute.withName("/senitel"))
                }
            },
        },
      int() => throw "unknown value"
    };

Widget endDrawerHeading(
        BuildContext context, String headline, GlobalKey<ScaffoldState> k,
        {Color? titleColor, Color? backroundColor}) =>
    SliverAppBar(
      expandedHeight: 152,
      collapsedHeight: kToolbarHeight,
      automaticallyImplyLeading: false,
      backgroundColor: backroundColor,
      actions: [Container()],
      pinned: true,
      leading: BackButton(
        onPressed: () {
          k.currentState?.closeEndDrawer();
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
          title: Text(
        headline,
        style: TextStyle(color: titleColor),
      )),
    );

Widget? makeEndDrawerSettings(
    BuildContext context, GlobalKey<ScaffoldState> key) {
  if (Platform.isAndroid || Platform.isIOS) {
    return null;
  }

  return Drawer(
      child: CustomScrollView(
    slivers: [
      endDrawerHeading(
          context, AppLocalizations.of(context)!.settingsPageName, key),
      SettingsList(sliver: true, scaffoldKey: key)
    ],
  ));
}

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

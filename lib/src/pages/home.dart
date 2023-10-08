// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../main.dart';
import '../db/initalize_db.dart';
import '../db/post_tags.dart';
import '../db/schemas/settings.dart';
import '../db/state_restoration.dart';
import '../interfaces/booru.dart';
import '../widgets/skeletons/make_home_skeleton.dart';
import '../widgets/skeletons/skeleton_state.dart';
import 'booru/main.dart';
import 'favorites.dart';
import 'gallery/directories.dart';
import 'more_page.dart';
import 'settings/settings_widget.dart';
import 'tags.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final state = SkeletonState();
  int currentRoute = 0;
  bool showNavBar = true;
  late final controller = AnimationController(vsync: this);
  final menuController = MenuController();

  late final Isar mainGrid;

  @override
  void dispose() {
    mainGrid.close().then((value) => restartOver());
    state.dispose();

    controller.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final settings = Settings.fromDb();

    mainGrid = DbsOpen.primaryGrid(settings.selectedBooru);

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      changeSystemUiOverlay(context);
      initPostTags(context);
    });

    if (settings.path.isEmpty) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        Navigator.push(
            context,
            DialogRoute(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                      AppLocalizations.of(context)!.beforeYouContinueTitle),
                  content:
                      Text(AppLocalizations.of(context)!.needChooseDirectory),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, "/booru");
                        },
                        child: Text(AppLocalizations.of(context)!.later)),
                    TextButton(
                        onPressed: () {
                          Settings.chooseDirectory((e) {}).then((success) {
                            if (success) {
                              Navigator.pop(context);
                              Navigator.pushReplacementNamed(context, "/booru");
                            }
                          });
                        },
                        child: Text(AppLocalizations.of(context)!.choose))
                  ],
                );
              },
            ));
      });
    }
  }

  void _hideShowNavBar(bool hide) {
    setState(() {
      showNavBar = !hide;
    });
  }

  Widget _currentPage(BuildContext context) => switch (currentRoute) {
        0 => MainBooruGrid(
            mainGrid: mainGrid,
            hideShowNavBar: _hideShowNavBar,
            procPop: _procPop),
        1 => GalleryDirectories(
            hideShowNavBar: _hideShowNavBar,
            procPop: _procPop,
          ),
        2 => FavoritesPage(
            hideShowNavBar: _hideShowNavBar,
            procPop: _procPop,
          ),
        3 => WillPopScope(
            onWillPop: _procPop,
            child: TagsPage(
              tagManager:
                  TagManager.fromEnum(Settings.fromDb().selectedBooru, true),
              booru: BooruAPI.fromEnum(Settings.fromDb().selectedBooru,
                  page: null),
              mainFocus: state.mainFocus,
            )),
        4 =>
          WillPopScope(onWillPop: _procPop, child: const MorePage().animate()),
        int() => throw "unimpl",
      };

  void _switchPage(int to) {
    if (to == currentRoute) {
      return;
    }
    controller.animateTo(1).then((value) {
      currentRoute = to;
      controller.reset();
      setState(() {});
    });
  }

  Future<bool> _procPop() {
    if (currentRoute != 0) {
      _switchPage(0);
      return Future.value(false);
    }

    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return makeHomeSkeleton(
        context,
        "Home",
        state,
        Animate(
            target: 0,
            effects: [FadeEffect(duration: 50.ms, begin: 1, end: 0)],
            controller: controller,
            child: _currentPage(context)),
        showNavBar: showNavBar,
        selectedRoute: currentRoute, onDestinationSelected: (route) {
      _switchPage(route);
    }, destinations: [
      MenuAnchor(
        anchorTapClosesMenu: true,
        alignmentOffset: const Offset(8, 8),
        controller: menuController,
        menuChildren: Booru.values
            .map((e) => ListTile(
                  title: Text(e.string),
                  onTap: () {
                    selectBooru(context, Settings.fromDb(), e);
                  },
                ))
            .toList(),
        child: GestureDetector(
          onTap: () {
            _switchPage(0);
          },
          onLongPress: () {
            menuController.open();
          },
          child: AbsorbPointer(
            child: NavigationDestination(
              icon: const Icon(Icons.image),
              label: Settings.fromDb().selectedBooru.string,
            ),
          ),
        ),
      ),
      NavigationDestination(
        icon: const Icon(Icons.photo_album),
        label: AppLocalizations.of(context)!.galleryLabel,
      ),
      NavigationDestination(
        icon: const Icon(Icons.favorite),
        label: AppLocalizations.of(context)!.favoritesLabel,
      ),
      NavigationDestination(
        icon: const Icon(Icons.tag),
        label: AppLocalizations.of(context)!.tagsLabel,
      ),
      const NavigationDestination(
        icon: Icon(Icons.more_horiz),
        label: "More", // TODO: change
      )
    ]);
  }
}

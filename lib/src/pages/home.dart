// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/pages/notes_page.dart';
import 'package:gallery/src/pages/settings/network_status.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../main.dart';
import '../db/initalize_db.dart';
import '../db/tags/post_tags.dart';
import '../db/schemas/booru/post.dart';
import '../db/schemas/settings/settings.dart';
import '../db/state_restoration.dart';
import '../interfaces/booru/booru_api.dart';
import '../widgets/grid/selection_glue_state.dart';
import '../widgets/skeletons/home_skeleton.dart';
import '../widgets/skeletons/skeleton_state.dart';
import 'booru/main.dart';
import 'favorites.dart';
import 'gallery/directories.dart';
import 'more_page.dart';
import 'settings/settings_widget.dart';
import 'tags_page.dart';

class Home extends StatefulWidget {
  final CallbackDescriptionNested? callback;

  const Home({super.key, this.callback});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  late final controllerNavBar = AnimationController(vsync: this);
  final state = SkeletonState();
  int currentRoute = 0;
  late final controller = AnimationController(vsync: this);
  final menuController = MenuController();

  late final SelectionGlueState glueState;

  late final Isar mainGrid;

  Future<int>? status;

  final Map<void Function(int?, bool), Null> m = {};

  late final refreshInterface = RefreshingStatusInterface(
    save: (s) {
      status?.ignore();
      status = s;

      status?.then((value) {
        for (final f in m.keys) {
          f(value, false);
        }
      }).onError((error, stackTrace) {
        for (final f in m.keys) {
          f(null, false);
        }
      }).whenComplete(() => status = null);
    },
    register: (f) {
      if (status != null) {
        f(null, true);
      }

      m[f] = null;
    },
    unregister: (f) => m.remove(f),
    reset: () {
      status?.ignore();
      status = null;
    },
  );

  @override
  void dispose() {
    NetworkStatus.g.notify = null;
    mainGrid.close().then((value) => restartOver());
    state.dispose();

    controller.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    glueState = SelectionGlueState(
        //   playAnimation: (backward) {
        //   if (backward) {
        //     return controllerNavBar.animateBack(0);
        //   }
        //   // return controller.animateTo(1);

        //   return controllerNavBar.animateTo(1);
        // }
        );

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
                        },
                        child: Text(AppLocalizations.of(context)!.later)),
                    TextButton(
                        onPressed: () {
                          Settings.chooseDirectory((e) {});
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.choose))
                  ],
                );
              },
            ));
      });
    }
    NetworkStatus.g.notify = () {
      try {
        setState(() {});
      } catch (_) {}
    };
  }

  bool keyboardVisible() => MediaQuery.viewInsetsOf(context).bottom != 0;

  Widget _currentPage(BuildContext context) {
    if (widget.callback != null) {
      if (currentRoute == 0) {
        return GlueProvider<SystemGalleryDirectory>(
            glue: glueState.glue(keyboardVisible, setState),
            child: GalleryDirectories(
              nestedCallback: widget.callback,
              procPop: _procPop,
              bottomPadding: keyboardVisible() ? 0 : 80,
            ));
      } else {
        return NotesPage(
          callback: widget.callback,
          bottomPadding: 80,
        );
      }
    }

    return switch (currentRoute) {
      0 => GlueProvider<Post>(
          glue: glueState.glue(keyboardVisible, setState),
          child: MainBooruGrid(
            mainGrid: mainGrid,
            refreshingInterface: refreshInterface,
            procPop: _procPop,
          ),
        ),
      1 => GlueProvider<SystemGalleryDirectory>(
          glue: glueState.glue(keyboardVisible, setState),
          child: GalleryDirectories(
            procPop: _procPop,
            bottomPadding: keyboardVisible() ? 0 : 80,
          ),
        ),
      2 => GlueProvider<FavoriteBooru>(
          glue: glueState.glue(keyboardVisible, setState),
          child: FavoritesPage(procPop: _procPop),
        ),
      3 => PopScope(
          canPop: currentRoute == 0,
          onPopInvoked: _procPop,
          child: TagsPage(
            tagManager: TagManager.fromEnum(Settings.fromDb().selectedBooru),
            booru:
                BooruAPI.fromEnum(Settings.fromDb().selectedBooru, page: null),
            mainFocus: state.mainFocus,
          )),
      4 => PopScope(
          canPop: currentRoute == 0,
          onPopInvoked: _procPop,
          child: const MorePage().animate()),
      int() => throw "unimpl",
    };
  }

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

  void _procPop(bool pop) {
    if (!pop) {
      _switchPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSkeleton(
      "Home",
      state,
      (context) {
        return Animate(
            target: 0,
            effects: [FadeEffect(duration: 50.ms, begin: 1, end: 0)],
            controller: controller,
            child: _currentPage(context));
      },
      navBar: Animate(
          controller: controllerNavBar,
          target: glueState.actions != null ? 1 : 0,
          effects: [
            MoveEffect(
              curve: Easing.emphasizedAccelerate,
              begin: Offset.zero,
              end: Offset(0, 100 + MediaQuery.viewInsetsOf(context).bottom),
            ),
            SwapEffect(
              builder: (context, _) {
                return glueState.actions != null
                    ? GlueBottomAppBar(glueState.actions!)
                    : const SizedBox();
              },
            )
          ],
          child: NavigationBar(
            backgroundColor:
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
            selectedIndex: currentRoute,
            onDestinationSelected: (route) {
              _switchPage(route);
            },
            destinations: widget.callback != null
                ? [
                    NavigationDestination(
                      icon: const Icon(Icons.collections),
                      label: AppLocalizations.of(context)!.galleryLabel,
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.sticky_note_2),
                      label: "Notes", // TODO: change
                    ),
                  ]
                : [
                    NavigationDestination(
                      icon: MenuAnchor(
                        consumeOutsideTap: true,
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
                          onLongPress: () {
                            menuController.open();
                          },
                          child: const Icon(Icons.image),
                        ),
                      ),
                      label: Settings.fromDb().selectedBooru.string,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.collections),
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
                    NavigationDestination(
                      icon: const Icon(Icons.more_horiz),
                      label: AppLocalizations.of(context)!.more, // TODO: change
                    )
                  ],
          )),
      selectedRoute: currentRoute,
    );
  }
}

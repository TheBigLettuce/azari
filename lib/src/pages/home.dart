// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/interfaces/refreshing_status_interface.dart';
import 'package:gallery/src/pages/anime/anime.dart';
import 'package:gallery/src/pages/gallery/callback_description_nested.dart';
import 'package:gallery/src/pages/more/notes/notes_page.dart';
import 'package:gallery/src/pages/more/settings/network_status.dart';
import 'package:gallery/src/widgets/grid/glue_bottom_app_bar.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/notifiers/selection_count.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../main.dart';
import '../db/initalize_db.dart';
import '../db/tags/post_tags.dart';
import '../db/schemas/booru/post.dart';
import '../db/schemas/settings/settings.dart';
import '../db/state_restoration.dart';
import '../interfaces/booru/booru_api_state.dart';
import '../widgets/grid/selection/selection_glue_state.dart';
import '../widgets/skeletons/home_skeleton.dart';
import '../widgets/skeletons/skeleton_state.dart';
import 'booru/main.dart';
import 'more/favorite_booru_page.dart';
import 'gallery/directories.dart';
import 'more/more_page.dart';
import 'more/settings/settings_widget.dart';

part '../widgets/home/icons/anime_icon.dart';
part '../widgets/home/icons/gallery_icon.dart';
part '../widgets/home/icons/booru_icon.dart';
part '../widgets/home/icons/favorites_icon.dart';
part '../widgets/home/navigator_shell.dart';
part '../widgets/home/main_grid_refreshing_interface.dart';
part '../widgets/home/change_page_mixin.dart';
part '../widgets/home/animated_icons_mixin.dart';
part '../widgets/home/before_you_continue_dialog_mixin.dart';

class Home extends StatefulWidget {
  final CallbackDescriptionNested? callback;

  const Home({super.key, this.callback});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with
        TickerProviderStateMixin,
        _MainGridRefreshingInterfaceMixin,
        _ChangePageMixin,
        _AnimatedIconsMixin,
        _BeforeYouContinueDialogMixin {
  final state = SkeletonState();

  bool isRefreshing = false;

  bool hideNavBar = false;

  @override
  void initState() {
    super.initState();

    final settings = Settings.fromDb();

    initChangePage(this, settings);
    initIcons(this);

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      changeSystemUiOverlay(context);
      initPostTags(context);
    });

    maybeBeforeYouContinueDialog(context, settings);

    NetworkStatus.g.notify = () {
      try {
        setState(() {});
      } catch (_) {}
    };
  }

  @override
  void dispose() {
    disposeIcons();
    disposeChangePage();

    NetworkStatus.g.notify = null;

    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edgeInsets = MediaQuery.viewPaddingOf(context);

    return SelectionCountNotifier(
      count: glueState.count ?? 0,
      child: HomeSkeleton(
        "Home",
        state,
        (context) => _currentPage(context, this, this, edgeInsets),
        navBar: Animate(
            controller: controllerNavBar,
            target: glueState.actions != null ? 1 : 0,
            effects: [
              MoveEffect(
                curve: Easing.emphasizedAccelerate,
                begin: Offset.zero,
                end: Offset(0, 100 + edgeInsets.bottom),
              ),
              SwapEffect(
                builder: (context, _) {
                  return glueState.actions != null
                      ? GlueBottomAppBar(glueState.actions!)
                      : Padding(
                          padding: EdgeInsets.only(bottom: edgeInsets.bottom));
                },
              )
            ],
            child: NavigationBar(
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              backgroundColor:
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
              selectedIndex: currentRoute,
              onDestinationSelected: (route) => _switchPage(this, route),
              destinations: widget.callback != null
                  ? iconsGalleryNotes(context)
                  : icons(context, currentRoute),
            )),
        selectedRoute: currentRoute,
      ),
    );
  }
}

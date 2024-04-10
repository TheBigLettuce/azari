// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/pages/more/blacklisted_posts.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/page_description.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/db/schemas/gallery/blacklisted_directory.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/loaders/linear_isar_loader.dart';
import '../../widgets/grid_frame/wrappers/wrap_grid_page.dart';
import '../../widgets/skeletons/grid.dart';

class BlacklistedPage extends StatefulWidget {
  final SelectionGlue Function([Set<GluePreferences>]) generateGlue;

  const BlacklistedPage({
    super.key,
    required this.generateGlue,
  });

  @override
  State<BlacklistedPage> createState() => _BlacklistedPageState();
}

class _BlacklistedPageState extends State<BlacklistedPage> {
  late final StreamSubscription blacklistedWatcher;
  final loader = LinearIsarLoader<BlacklistedDirectory>(
      BlacklistedDirectorySchema,
      Dbs.g.blacklisted,
      (offset, limit, s, sort, mode) => Dbs.g.blacklisted.blacklistedDirectorys
          .filter()
          .nameContains(s, caseSensitive: false)
          .offset(offset)
          .limit(limit)
          .findAllSync());
  late final state = GridSkeletonStateFilter<BlacklistedDirectory>(
    filter: loader.filter,
    transform: (cell) => cell,
  );

  late final SearchFilterGrid<BlacklistedDirectory> search;

  @override
  void initState() {
    super.initState();
    search = SearchFilterGrid(state, null);

    blacklistedWatcher = BlacklistedDirectory.watch((event) {
      search.performSearch(search.searchTextController.text);
      setState(() {});
    });
  }

  @override
  void dispose() {
    blacklistedWatcher.cancel();
    state.dispose();
    search.dispose();

    super.dispose();
  }

  bool hideBlacklistedImages = true;

  @override
  Widget build(BuildContext context) {
    return WrapGridPage(
      provided: widget.generateGlue,
      child: GridSkeleton(
        state,
        (context) => GridFrame<BlacklistedDirectory>(
          key: state.gridKey,
          layout: const GridSettingsLayoutBehaviour(GridSettingsBase.list),
          getCell: loader.getCell,
          functionality: GridFunctionality(
            registerNotifiers: (child) => HideBlacklistedImagesNotifier(
              hiding: hideBlacklistedImages,
              child: child,
            ),
            search: OverrideGridSearchWidget(
              SearchAndFocus(
                  search.searchWidget(context,
                      hint: AppLocalizations.of(context)!.blacklistedPage),
                  search.searchFocus),
            ),
            selectionGlue: GlueProvider.generateOf(context)(),
            refreshingStatus: state.refreshingStatus,
            // imageViewDescription: ImageViewDescription(
            //   imageViewKey: state.imageViewKey,
            // ),
            refresh: SynchronousGridRefresh(() => loader.count()),
          ),
          mainFocus: state.mainFocus,
          description: GridDescription(
            pages: PageSwitcherIcons(
              const [PageIcon(Icons.image)],
              (context, state, i) => PageDescription(
                appIcons: [
                  IconButton(
                      onPressed: () {
                        hideBlacklistedImages = !hideBlacklistedImages;

                        setState(() {});
                      },
                      icon: hideBlacklistedImages
                          ? const Icon(Icons.image_rounded)
                          : const Icon(Icons.hide_image_rounded))
                ],
                slivers: [
                  BlacklistedPostsPage(
                    generateGlue: widget.generateGlue,
                  )
                ],
              ),
              overrideHomeIcon: const Icon(Icons.folder),
            ),
            actions: [
              GridAction(
                Icons.restore_page,
                (selected) {
                  BlacklistedDirectory.deleteAll(selected
                      .cast<BlacklistedDirectory>()
                      .map((e) => e.bucketId)
                      .toList());
                },
                true,
              )
            ],
            menuButtonItems: [
              IconButton(
                  onPressed: () {
                    BlacklistedDirectory.clear();
                    chooseGalleryPlug().notify(null);
                  },
                  icon: const Icon(Icons.delete))
            ],
            keybindsDescription: AppLocalizations.of(context)!.blacklistedPage,
            gridSeed: state.gridSeed,
          ),
        ),
        canPop: true,
      ),
    );
  }
}

class HideBlacklistedImagesNotifier extends InheritedWidget {
  final bool hiding;

  const HideBlacklistedImagesNotifier({
    super.key,
    required this.hiding,
    required super.child,
  });

  static bool of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<HideBlacklistedImagesNotifier>();

    return widget!.hiding;
  }

  @override
  bool updateShouldNotify(HideBlacklistedImagesNotifier oldWidget) =>
      hiding != oldWidget.hiding;
}

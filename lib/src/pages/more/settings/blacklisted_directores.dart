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
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/db/schemas/gallery/blacklisted_directory.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../db/loaders/linear_isar_loader.dart';
import '../../../widgets/grid_frame/wrappers/wrap_grid_page.dart';
import '../../../widgets/skeletons/grid.dart';

class BlacklistedDirectories extends StatefulWidget {
  final SelectionGlue<J> Function<J extends Cell>() generateGlue;

  const BlacklistedDirectories({
    super.key,
    required this.generateGlue,
  });

  @override
  State<BlacklistedDirectories> createState() => _BlacklistedDirectoriesState();
}

class _BlacklistedDirectoriesState extends State<BlacklistedDirectories> {
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
    transform: (cell, sort) => cell,
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

  @override
  Widget build(BuildContext context) {
    return WrapGridPage<BlacklistedDirectory>(
        provided: widget.generateGlue,
        scaffoldKey: state.scaffoldKey,
        child: GridSkeleton(
          state,
          (context) => GridFrame<BlacklistedDirectory>(
            key: state.gridKey,
            layout: const GridSettingsLayoutBehaviour(GridSettingsBase.list),
            refreshingStatus: state.refreshingStatus,
            getCell: loader.getCell,
            systemNavigationInsets: MediaQuery.viewPaddingOf(context),
            functionality: GridFunctionality(
              search: OverrideGridSearchWidget(
                SearchAndFocus(
                    search.searchWidget(context,
                        hint: AppLocalizations.of(context)!
                            .blacklistedDirectoriesPageName),
                    search.searchFocus),
              ),
              selectionGlue: GlueProvider.of(context),
              refresh: SynchronousGridRefresh(() => loader.count()),
            ),
            imageViewDescription: ImageViewDescription(
              imageViewKey: state.imageViewKey,
            ),
            mainFocus: state.mainFocus,
            description: GridDescription(
              actions: [
                GridAction(
                  Icons.restore_page,
                  (selected) {
                    BlacklistedDirectory.deleteAll(
                        selected.map((e) => e.bucketId).toList());
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
              keybindsDescription:
                  AppLocalizations.of(context)!.blacklistedDirectoriesPageName,
              gridSeed: state.gridSeed,
            ),
          ),
          canPop: true,
          overrideOnPop: (pop, hideAppBar) {
            if (hideAppBar()) {
              setState(() {});
              return;
            }
          },
        ));
  }
}

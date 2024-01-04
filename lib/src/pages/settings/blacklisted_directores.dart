// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:gallery/src/db/schemas/gallery/blacklisted_directory.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/layouts/list_layout.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/loaders/linear_isar_loader.dart';
import '../../widgets/grid/wrap_grid_page.dart';
import '../../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../../widgets/skeletons/grid_skeleton.dart';

class BlacklistedDirectories extends StatefulWidget {
  const BlacklistedDirectories({super.key});

  @override
  State<BlacklistedDirectories> createState() => _BlacklistedDirectoriesState();
}

class _BlacklistedDirectoriesState extends State<BlacklistedDirectories>
    with SearchFilterGrid<BlacklistedDirectory> {
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

  @override
  void initState() {
    super.initState();
    searchHook(state);

    blacklistedWatcher = BlacklistedDirectory.watch((event) {
      performSearch(searchTextController.text);
      setState(() {});
    });
  }

  @override
  void dispose() {
    blacklistedWatcher.cancel();
    state.dispose();
    disposeSearch();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WrapGridPage<BlacklistedDirectory>(
        scaffoldKey: state.scaffoldKey,
        child: GridSkeleton(
          state,
          (context) => CallbackGrid<BlacklistedDirectory>(
              key: state.gridKey,
              getCell: loader.getCell,
              initalScrollPosition: 0,
              scaffoldKey: state.scaffoldKey,
              systemNavigationInsets: MediaQuery.systemGestureInsetsOf(context),
              hasReachedEnd: () => true,
              onBack: () => Navigator.pop(context),
              addFabPadding: true,
              selectionGlue: GlueProvider.of(context),
              searchWidget: SearchAndFocus(
                  searchWidget(context,
                      hint: AppLocalizations.of(context)!
                          .blacklistedDirectoriesPageName),
                  searchFocus),
              mainFocus: state.mainFocus,
              showCount: true,
              menuButtonItems: [
                IconButton(
                    onPressed: () {
                      BlacklistedDirectory.clear();
                      chooseGalleryPlug().notify(null);
                    },
                    icon: const Icon(Icons.delete))
              ],
              refresh: () => Future.value(loader.count()),
              description: GridDescription([
                GridAction(
                  Icons.restore_page,
                  (selected) {
                    BlacklistedDirectory.deleteAll(
                        selected.map((e) => e.bucketId).toList());
                  },
                  true,
                )
              ],
                  keybindsDescription: AppLocalizations.of(context)!
                      .blacklistedDirectoriesPageName,
                  layout: const ListLayout(unpressable: true))),
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

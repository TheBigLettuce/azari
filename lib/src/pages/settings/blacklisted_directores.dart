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
import 'package:gallery/src/db/schemas/blacklisted_directory.dart';
import 'package:gallery/src/db/schemas/settings.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/linear_isar_loader.dart';
import '../../widgets/grid/wrap_grid_page.dart';
import '../../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../../widgets/skeletons/make_grid_skeleton.dart';

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

    blacklistedWatcher = Dbs.g.blacklisted.blacklistedDirectorys
        .watchLazy(fireImmediately: true)
        .listen((event) {
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
    return WrappedGridPage<BlacklistedDirectory>(
        scaffoldKey: state.scaffoldKey,
        f: (glue) => makeGridSkeleton(
              context,
              state,
              CallbackGrid<BlacklistedDirectory>(
                  key: state.gridKey,
                  getCell: loader.getCell,
                  initalScrollPosition: 0,
                  scaffoldKey: state.scaffoldKey,
                  systemNavigationInsets:
                      MediaQuery.systemGestureInsetsOf(context),
                  hasReachedEnd: () => true,
                  aspectRatio: 1,
                  onBack: () => Navigator.pop(context),
                  immutable: false,
                  addFabPadding: true,
                  selectionGlue: glue,
                  searchWidget: SearchAndFocus(
                      searchWidget(
                        context,
                        hint: AppLocalizations.of(context)!
                            .blacklistedDirectoriesPageName
                            .toLowerCase(),
                      ),
                      searchFocus),
                  mainFocus: state.mainFocus,
                  unpressable: true,
                  showCount: true,
                  menuButtonItems: [
                    IconButton(
                        onPressed: () {
                          Dbs.g.blacklisted.writeTxnSync(() => Dbs
                              .g.blacklisted.blacklistedDirectorys
                              .clearSync());
                          chooseGalleryPlug().notify(null);
                        },
                        icon: const Icon(Icons.delete))
                  ],
                  refresh: () => Future.value(loader.count()),
                  description: GridDescription([
                    GridBottomSheetAction(Icons.restore_page, (selected) {
                      Dbs.g.blacklisted.writeTxnSync(() {
                        return Dbs.g.blacklisted.blacklistedDirectorys
                            .deleteAllByBucketIdSync(
                                selected.map((e) => e.bucketId).toList());
                      });
                    },
                        true,
                        const GridBottomSheetActionExplanation(
                          label: "Unblacklist", // TODO: change
                          body:
                              "Unblacklist selected directories.", // TODO: change
                        ))
                  ], GridColumn.two,
                      keybindsDescription: AppLocalizations.of(context)!
                          .blacklistedDirectoriesPageName,
                      listView: true)),
              canPop: !glue.isOpen() &&
                  state.gridKey.currentState?.showSearchBar == false,
              overrideOnPop: (pop, hideAppBar) {
                if (glue.isOpen()) {
                  state.gridKey.currentState?.selection.reset();
                  return;
                }

                if (hideAppBar()) {
                  setState(() {});
                  return;
                }
              },
            ));
  }
}

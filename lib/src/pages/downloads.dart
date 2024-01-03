// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/grid/actions/downloads.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/downloader/download_file.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/enums/grid_column.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/loaders/linear_isar_loader.dart';
import '../widgets/grid/wrap_grid_page.dart';
import '../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../widgets/skeletons/grid_skeleton.dart';

class Downloads extends StatefulWidget {
  const Downloads({super.key});

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads>
    with SearchFilterGrid<DownloadFile> {
  final loader = LinearIsarLoader<DownloadFile>(DownloadFileSchema, Dbs.g.main,
      (offset, limit, s, sort, mode) {
    return Dbs.g.main.downloadFiles
        .where()
        .sortByInProgressDesc()
        .offset(offset)
        .limit(limit)
        .findAllSync();
  });

  late final StreamSubscription<void> _updates;

  late final state = GridSkeletonStateFilter<DownloadFile>(
    filter: loader.filter,
    transform: (cell, sort) => cell,
  );

  AnimationController? refreshController;
  AnimationController? deleteController;

  @override
  void initState() {
    super.initState();
    searchHook(state);

    Downloader.g.markStale();

    _updates = Dbs.g.main.downloadFiles
        .watchLazy(fireImmediately: true)
        .listen((_) async {
      performSearch(searchTextController.text);
    });
  }

  @override
  void dispose() {
    _updates.cancel();
    disposeSearch();
    state.dispose();

    super.dispose();
  }

  Segments<DownloadFile> _makeSegments(BuildContext context) => Segments(
        "Unknown", // TODO: change
        hidePinnedIcon: true,
        limitLabelChildren: 6,
        segment: (cell) {
          return (Downloader.g.downloadDescription(cell), true);
        },
        onLabelPressed: (label, children) {
          if (children.isEmpty) {
            return;
          }

          if (label == kDownloadInProgress) {
            Downloader.g.markStale(override: children);
          } else if (label == kDownloadOnHold) {
            Downloader.g.addAll(children, state.settings);
          } else if (label == kDownloadFailed) {
            final n = (6 - children.length);

            if (!n.isNegative && n != 0) {
              Downloader.g.addAll([
                ...children,
                ...Dbs.g.main.downloadFiles
                    .where()
                    .inProgressEqualTo(false)
                    .filter()
                    .isFailedEqualTo(false)
                    .sortByDateDesc()
                    .limit(6 - children.length)
                    .findAllSync()
              ], state.settings);
            } else {
              Downloader.g.addAll(children, state.settings);
            }
          }
        },
      );

  @override
  Widget build(BuildContext context) {
    return WrappedGridPage<DownloadFile>(
        scaffoldKey: state.scaffoldKey,
        child: GridSkeleton(
          state,
          (context) => CallbackGrid<DownloadFile>(
              key: state.gridKey,
              getCell: loader.getCell,
              initalScrollPosition: 0,
              scaffoldKey: state.scaffoldKey,
              systemNavigationInsets: MediaQuery.systemGestureInsetsOf(context),
              hasReachedEnd: () => true,
              selectionGlue: GlueProvider.of(context),
              showCount: true,
              onBack: () => Navigator.pop(context),
              menuButtonItems: [
                IconButton(
                    onPressed: () {
                      if (deleteController != null) {
                        deleteController!.forward(from: 0);
                      }
                      Downloader.g.removeAll();
                    },
                    icon: const Icon(Icons.close).animate(
                        onInit: (controller) => deleteController = controller,
                        effects: const [FlipEffect(begin: 1, end: 0)],
                        autoPlay: false)),
              ],
              inlineMenuButtonItems: true,
              immutable: false,
              unpressable: true,
              searchWidget: SearchAndFocus(
                  searchWidget(context,
                      hint: AppLocalizations.of(context)!.downloadsPageName),
                  searchFocus),
              mainFocus: state.mainFocus,
              refresh: () => Future.value(loader.count()),
              description: GridDescription([
                DownloadsActions.delete(context),
              ],
                  keybindsDescription:
                      AppLocalizations.of(context)!.downloadsPageName,
                  layout: SegmentListLayout(
                      _makeSegments(context), GridColumn.two))),
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

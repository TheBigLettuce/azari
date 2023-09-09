// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Downloads extends StatefulWidget {
  const Downloads({super.key});

  @override
  State<Downloads> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> with SearchFilterGrid<File> {
  final loader = LinearIsarLoader<File>(FileSchema, settingsIsar(),
      (offset, limit, s, sort, mode) {
    return settingsIsar()
        .files
        .where()
        .sortByInProgressDesc()
        .offset(offset)
        .limit(limit)
        .findAllSync();
  });

  late final StreamSubscription<void> _updates;
  final downloader = Downloader();

  late final state = GridSkeletonStateFilter<File>(
    filter: loader.filter,
    index: kDownloadsDrawerIndex,
    transform: (cell, sort) => cell,
  );

  AnimationController? refreshController;
  AnimationController? deleteController;

  @override
  void initState() {
    super.initState();
    searchHook(state);

    downloader.markStale();

    _updates =
        settingsIsar().files.watchLazy(fireImmediately: true).listen((_) async {
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

  void _refresh() {
    if (refreshController != null) {
      refreshController!.forward(from: 0);
    }

    downloader.markStale();
  }

  @override
  Widget build(BuildContext context) {
    return makeGridSkeleton(
        context,
        state,
        CallbackGrid<File>(
            key: state.gridKey,
            getCell: loader.getCell,
            initalScrollPosition: 0,
            scaffoldKey: state.scaffoldKey,
            systemNavigationInsets: MediaQuery.systemGestureInsetsOf(context),
            hasReachedEnd: () => true,
            aspectRatio: 1,
            menuButtonItems: [
              IconButton(
                  onPressed: () {
                    if (deleteController != null) {
                      deleteController!.forward(from: 0);
                    }
                    downloader.removeFailed();
                  },
                  icon: const Icon(Icons.close).animate(
                      onInit: (controller) => deleteController = controller,
                      effects: const [FlipEffect(begin: 1, end: 0)],
                      autoPlay: false)),
              IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh).animate(
                      onInit: (controller) => refreshController = controller,
                      effects: const [RotateEffect()],
                      autoPlay: false)),
            ],
            inlineMenuButtonItems: true,
            immutable: false,
            unpressable: true,
            hideShowFab: ({required bool fab, required bool foreground}) =>
                state.updateFab(setState, fab: fab, foreground: foreground),
            segments: Segments(
              (cell) {
                return (Downloader().downloadDescription(cell), true);
              },
              "Unknown",
              onLabelPressed: (label, children) {
                if (children.isEmpty) {
                  return;
                }

                if (label == kDownloadFailed) {
                  for (final d in children) {
                    downloader.add(d);
                  }
                }
              },
            ),
            searchWidget: SearchAndFocus(
                searchWidget(context,
                    hint: AppLocalizations.of(context)!
                        .downloadsPageName
                        .toLowerCase()),
                searchFocus),
            mainFocus: state.mainFocus,
            refresh: () => Future.value(loader.count()),
            description: GridDescription(
                kDownloadsDrawerIndex,
                [
                  GridBottomSheetAction(Icons.more_horiz, (selected) {
                    if (selected.isEmpty) {
                      return;
                    }
                    final file = selected.first;
                    Navigator.push(
                        context,
                        DialogRoute(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                          AppLocalizations.of(context)!.no)),
                                  TextButton(
                                      onPressed: () {
                                        downloader.retry(file);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                          AppLocalizations.of(context)!.yes)),
                                ],
                                title: Text(downloader.downloadAction(file)),
                                content: Text(file.name),
                              );
                            }));
                  },
                      true,
                      const GridBottomSheetActionExplanation(
                        label: "Retry or delete", // TODO: change
                        body:
                            "Retry or delete the downloads entry.", // TODO: change
                      ),
                      showOnlyWhenSingle: true)
                ],
                GridColumn.two,
                keybindsDescription:
                    AppLocalizations.of(context)!.downloadsPageName,
                listView: true)));
  }
}

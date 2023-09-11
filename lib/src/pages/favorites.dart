// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/favorite_booru.dart';
import 'package:gallery/src/schemas/local_tag_dictionary.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:isar/isar.dart';

import '../actions/booru_grid.dart';
import '../booru/tags/tags.dart';
import '../schemas/download_file.dart';
import '../schemas/settings.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SearchFilterGrid<FavoriteBooru> {
  final booru = BooruAPI.fromSettings();
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  Map<String, int>? segments;

  bool segmented = false;

  late final loader = LinearIsarLoader<FavoriteBooru>(
      FavoriteBooruSchema, settingsIsar(), (offset, limit, s, sort, mode) {
    if (mode == FilteringMode.group) {
      return settingsIsar()
          .favoriteBoorus
          .filter()
          .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
          .sortByGroupDesc()
          .thenByCreatedAtDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    } else if (mode == FilteringMode.same) {
      return settingsIsar()
          .favoriteBoorus
          .filter()
          .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
          .sortByMd5()
          .thenByCreatedAtDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    }

    return settingsIsar()
        .favoriteBoorus
        .filter()
        .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
        .sortByCreatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAllSync();
  })
    ..filter.passFilter = (cells, data, end) {
      if (currentFilteringMode() == FilteringMode.group) {
        segments = segments ?? {};

        for (final e in cells) {
          segments![e.group ?? "Ungrouped"] =
              (segments![e.group ?? "Ungrouped"] ?? 0) + 1;
        }
      } else {
        segments = null;
      }

      return switch (currentFilteringMode()) {
        FilteringMode.same => _same(cells, data, end),
        FilteringMode() => (cells, data)
      };
    };

  (Iterable<FavoriteBooru>, dynamic) _same(
      Iterable<FavoriteBooru> cells, Map<String, Set<String>>? data, bool end) {
    data = data ?? {};

    FavoriteBooru? prevCell;
    for (final e in cells) {
      if (prevCell != null) {
        if (prevCell.md5 == e.md5) {
          final prev = data[e.md5] ?? {prevCell.fileUrl};

          data[e.md5] = {...prev, e.fileUrl};
        }
      }

      prevCell = e;
    }

    if (end) {
      return (
        () sync* {
          for (final ids in data!.values) {
            for (final i in ids) {
              final f = loader.instance.favoriteBoorus.getByFileUrlSync(i)!;
              f.isarId = null;
              yield f;
            }
          }
        }(),
        null
      );
    }

    return ([], data);
  }

  late final state = GridSkeletonStateFilter<FavoriteBooru>(
    index: kFavoritesDrawerIndex,
    filter: loader.filter,
    unsetFilteringModeOnReset: false,
    hook: (selected) {
      segments = null;
      if (selected == FilteringMode.group) {
        segmented = true;
        setState(() {});
      } else {
        segmented = false;
        setState(() {});
      }

      Settings.saveToDb(Settings.fromDb().copy(favoritesPageMode: selected));

      return SortingMode.none;
    },
    defaultMode: FilteringMode.tag,
    filteringModes: {
      FilteringMode.tag,
      FilteringMode.group,
      FilteringMode.same,
    },
    transform: (FavoriteBooru cell, SortingMode sort) {
      return cell;
    },
  );

  Future<void> _download(int i) async {
    final p = loader.getCell(i);

    PostTags().addTagsPost(p.filename(), p.tags, true);

    return Downloader()
        .add(File.d(p.fileDownloadUrl(), booru.booru.url, p.filename()));
  }

  @override
  void initState() {
    super.initState();
    searchHook(state);

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      setFilteringMode(state.settings.favoritesPageMode);
      setLocalTagCompleteF((string) {
        final result = settingsIsar()
            .localTagDictionarys
            .filter()
            .tagContains(string)
            .sortByFrequencyDesc()
            .limit(10)
            .findAllSync();

        return Future.value(result.map((e) => e.tag).toList());
      });

      performSearch("");

      setState(() {});
    });

    settingsWatcher = settingsIsar().settings.watchObject(0).listen((event) {
      state.settings = event!;

      setState(() {});
    });

    favoritesWatcher = settingsIsar()
        .favoriteBoorus
        .watchLazy(fireImmediately: false)
        .listen((event) {
      performSearch(searchTextController.text);
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    state.dispose();
    disposeSearch();

    super.dispose();
  }

  GridBottomSheetAction<FavoriteBooru> _addToGroup() {
    return GridBottomSheetAction(Icons.group_work_outlined, (selected) {
      if (selected.isEmpty) {
        return;
      }

      Navigator.push(
          context,
          DialogRoute(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text(
                  "Group", // TODO: change
                ),
                content: TextFormField(
                  initialValue: () {
                    final g = selected.first.group;
                    for (final e in selected.skip(1)) {
                      if (g != e.group) {
                        return null;
                      }
                    }

                    return g;
                  }(),
                  onFieldSubmitted: (value) {
                    // state.gridKey.currentState?.mutationInterface
                    //     ?.setSource(0, loader.getCell);

                    segments = null;

                    for (var e in selected) {
                      e.group = value.isEmpty ? null : value;
                    }
                    settingsIsar().writeTxnSync(() => settingsIsar()
                        .favoriteBoorus
                        .putAllByFileUrlSync(selected));

                    Navigator.pop(context);
                  },
                ),
              );
            },
          ));
    },
        true,
        const GridBottomSheetActionExplanation(
          label: "Group", // TODO: change
          body: "Add selected items to the group.", // TODO: change
        ));
  }

  @override
  Widget build(BuildContext context) {
    return makeGridSkeleton<FavoriteBooru>(
      context,
      state,
      CallbackGrid(
        key: state.gridKey,
        hideShowFab: ({required bool fab, required bool foreground}) =>
            state.updateFab(setState, fab: fab, foreground: foreground),
        getCell: loader.getCell,
        initalScrollPosition: 0,
        scaffoldKey: state.scaffoldKey,
        addIconsImage: (p) => [
          BooruGridActions.favorites(context, p, showDeleteSnackbar: true),
          BooruGridActions.download(context, booru)
        ],
        systemNavigationInsets: MediaQuery.systemGestureInsetsOf(context),
        hasReachedEnd: () => true,
        hideAlias: true,
        download: _download,
        immutable: false,
        segments: segmented
            ? Segments(
                "Ungrouped",
                hidePinnedIcon: true,
                prebuiltSegments: segments,
              )
            : null,
        aspectRatio: state.settings.ratio.value,
        mainFocus: state.mainFocus,
        searchWidget: SearchAndFocus(
            searchWidget(
              context,
              hint: "favorites", // TODO: change
            ),
            searchFocus),
        refresh: () => Future.value(loader.count()),
        description: GridDescription(
            kFavoritesDrawerIndex,
            [BooruGridActions.download(context, booru), _addToGroup()],
            state.settings.picturesPerRow,
            keybindsDescription: "Favorites",
            listView: state.settings.booruListView),
      ),
    );
  }
}

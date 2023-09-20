// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/actions/favorites.dart';
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/cell/contentable.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/pages/booru/main.dart';
import 'package:gallery/src/schemas/favorite_booru.dart';
import 'package:gallery/src/schemas/local_tag_dictionary.dart';
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      FavoriteBooruSchema, Dbs.g.main, (offset, limit, s, sort, mode) {
    if (mode == FilteringMode.group) {
      return Dbs.g.main.favoriteBoorus
          .filter()
          .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
          .sortByGroupDesc()
          .thenByCreatedAtDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    } else if (mode == FilteringMode.same) {
      return Dbs.g.main.favoriteBoorus
          .filter()
          .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
          .sortByMd5()
          .thenByCreatedAtDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    }

    return Dbs.g.main.favoriteBoorus
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
        FilteringMode.gif => (
            cells.where((element) => element.fileDisplay() is NetGif),
            data
          ),
        FilteringMode.video => (
            cells.where((element) => element.fileDisplay() is NetVideo),
            data
          ),
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

      Settings.fromDb().copy(favoritesPageMode: selected).save();

      return SortingMode.none;
    },
    defaultMode: FilteringMode.tag,
    filteringModes: {
      FilteringMode.tag,
      FilteringMode.group,
      FilteringMode.gif,
      FilteringMode.video,
      FilteringMode.same,
    },
    transform: (FavoriteBooru cell, SortingMode sort) {
      return cell;
    },
  );

  Future<void> _download(int i) async {
    final p = loader.getCell(i);

    PostTags.g.addTagsPost(p.filename(), p.tags, true);

    return Downloader.g.add(
        DownloadFile.d(p.fileDownloadUrl(), booru.booru.url, p.filename()),
        state.settings);
  }

  @override
  void initState() {
    super.initState();
    searchHook(state);

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      setFilteringMode(state.settings.favoritesPageMode);
      setLocalTagCompleteF((string) {
        final result = Dbs.g.main.localTagDictionarys
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

    settingsWatcher = Dbs.g.main.settings.watchObject(0).listen((event) {
      state.settings = event!;

      setState(() {});
    });

    favoritesWatcher = Dbs.g.main.favoriteBoorus
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
        menuButtonItems: [
          gridSettingsButton(state.settings.favorites,
              selectHideName: null,
              selectRatio: (ratio) => state.settings
                  .copy(
                      favorites:
                          state.settings.favorites.copy(aspectRatio: ratio))
                  .save(),
              selectListView: (listView) => state.settings
                  .copy(
                      favorites:
                          state.settings.favorites.copy(listView: listView))
                  .save(),
              selectGridColumn: (columns) => state.settings
                  .copy(
                      favorites:
                          state.settings.favorites.copy(columns: columns))
                  .save())
        ],
        download: _download,
        immutable: false,
        segments: segmented
            ? Segments(
                "Ungrouped", // TODO: change
                hidePinnedIcon: true,
                prebuiltSegments: segments,
              )
            : null,
        aspectRatio: state.settings.favorites.aspectRatio.value,
        mainFocus: state.mainFocus,
        searchWidget: SearchAndFocus(
            searchWidget(context,
                hint:
                    AppLocalizations.of(context)!.favoritesLabel.toLowerCase()),
            searchFocus),
        refresh: () => Future.value(loader.count()),
        description: GridDescription(
            kFavoritesDrawerIndex,
            [
              BooruGridActions.download(context, booru),
              FavoritesActions.addToGroup(context, (selected) {
                final g = selected.first.group;
                for (final e in selected.skip(1)) {
                  if (g != e.group) {
                    return null;
                  }
                }

                return g;
              }, (selected, value) {
                for (var e in selected) {
                  e.group = value.isEmpty ? null : value;
                }
                Dbs.g.main.writeTxnSync(() =>
                    Dbs.g.main.favoriteBoorus.putAllByFileUrlSync(selected));

                Navigator.pop(context);
              })
            ],
            state.settings.favorites.columns,
            keybindsDescription: AppLocalizations.of(context)!.favoritesLabel,
            listView: state.settings.favorites.listView),
      ),
    );
  }
}

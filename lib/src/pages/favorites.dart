// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/grid/actions/favorites.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/interfaces/booru.dart';
import 'package:gallery/src/interfaces/contentable.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/pages/booru/main.dart';
import 'package:gallery/src/db/schemas/favorite_booru.dart';
import 'package:gallery/src/db/schemas/local_tag_dictionary.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/linear_isar_loader.dart';
import '../interfaces/filtering/filtering_mode.dart';
import '../interfaces/filtering/sorting_mode.dart';
import '../widgets/grid/actions/booru_grid.dart';
import '../db/post_tags.dart';
import '../db/schemas/download_file.dart';
import '../db/schemas/settings.dart';
import '../widgets/skeletons/grid_skeleton_state_filter.dart';
import '../widgets/skeletons/make_grid_skeleton.dart';

class FavoritesPage extends StatefulWidget {
  final Future<bool> Function() procPop;
  final SelectionGlue<FavoriteBooru> glue;

  const FavoritesPage({super.key, required this.procPop, required this.glue});

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
      if (s.isEmpty) {
        return Dbs.g.main.favoriteBoorus
            .where()
            .sortByGroupDesc()
            .thenByCreatedAtDesc()
            .offset(offset)
            .limit(limit)
            .findAllSync();
      }

      return Dbs.g.main.favoriteBoorus
          .filter()
          .groupContains(s)
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
      final filterMode = currentFilteringMode();

      if (filterMode == FilteringMode.group) {
        segments = segments ?? {};

        for (final e in cells) {
          segments![e.group ?? "Ungrouped"] =
              (segments![e.group ?? "Ungrouped"] ?? 0) + 1;
        }
      } else {
        segments = null;
      }

      return switch (filterMode) {
        FilteringMode.same => _same(cells, data, end),
        FilteringMode.ungrouped => (
            cells.where(
                (element) => element.group == null || element.group!.isEmpty),
            data
          ),
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
      FilteringMode.ungrouped,
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
        DownloadFile.d(
            url: p.fileDownloadUrl(),
            site: booru.booru.url,
            name: p.filename(),
            thumbUrl: p.previewUrl),
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

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = Dbs.g.main.favoriteBoorus
        .watchLazy(fireImmediately: false)
        .listen((event) {
      performSearch(searchTextController.text);
    });
  }

  GridBottomSheetAction<FavoriteBooru> _groupButton(BuildContext context) {
    return FavoritesActions.addToGroup(context, (selected) {
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
      Dbs.g.main.writeTxnSync(
          () => Dbs.g.main.favoriteBoorus.putAllByFileUrlSync(selected));

      Navigator.pop(context);
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
          getCell: loader.getCell,
          initalScrollPosition: 0,
          showCount: true,
          selectionGlue: widget.glue,
          scaffoldKey: state.scaffoldKey,
          addIconsImage: (p) => [
            BooruGridActions.favorites(context, p, showDeleteSnackbar: true),
            BooruGridActions.download(context, booru),
            _groupButton(context)
          ],
          systemNavigationInsets: EdgeInsets.only(
              bottom: MediaQuery.systemGestureInsetsOf(context).bottom +
                  (Scaffold.of(context).widget.bottomNavigationBar != null
                      ? 80
                      : 0)),
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
          addFabPadding:
              Scaffold.of(context).widget.bottomNavigationBar == null,
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
                  hint: AppLocalizations.of(context)!
                      .favoritesLabel
                      .toLowerCase()),
              searchFocus),
          refresh: () => Future.value(loader.count()),
          description: GridDescription([
            BooruGridActions.download(context, booru),
            _groupButton(context)
          ], state.settings.favorites.columns,
              keybindsDescription: AppLocalizations.of(context)!.favoritesLabel,
              listView: state.settings.favorites.listView),
        ), overrideOnPop: () {
      if (searchTextController.text.isNotEmpty) {
        resetSearch();
        return Future.value(false);
      }
      if (widget.glue.isOpen()) {
        state.gridKey.currentState?.selection.reset();
        return Future.value(false);
      }

      return widget.procPop();
    });
  }
}

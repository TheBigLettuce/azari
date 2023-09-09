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
import 'package:gallery/src/pages/senitel.dart';
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

  final loader = LinearIsarLoader<FavoriteBooru>(
      FavoriteBooruSchema,
      settingsIsar(),
      (offset, limit, s, sort, mode) => settingsIsar()
          .favoriteBoorus
          .filter()
          .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
          .sortByCreatedAtDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync());

  late final state = GridSkeletonStateFilter<FavoriteBooru>(
    index: kFavoritesDrawerIndex,
    filter: loader.filter,
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
      setFilteringMode(FilteringMode.tag);
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
          BooruGridActions.favorites(p),
          BooruGridActions.download(context, booru)
        ],
        systemNavigationInsets: MediaQuery.systemGestureInsetsOf(context),
        hasReachedEnd: () => true,
        hideAlias: true,
        download: _download,
        onBack: () => popUntilSenitel(context),
        immutable: false,
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
            [BooruGridActions.download(context, booru)],
            state.settings.picturesPerRow,
            keybindsDescription: "Favorites",
            listView: state.settings.booruListView),
      ),
    );
  }
}

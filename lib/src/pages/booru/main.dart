// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/schemas/favorite_booru.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import '../../actions/booru_grid.dart';
import '../../booru/downloader/downloader.dart';
import '../../booru/interface.dart';
import '../../booru/tags/tags.dart';
import '../../db/isar.dart';
import '../../db/state_restoration.dart';
import '../../schemas/download_file.dart';
import '../../schemas/post.dart';
import '../../schemas/settings.dart';
import '../../widgets/drawer/drawer.dart';
import '../../widgets/make_skeleton.dart';
import '../../widgets/notifiers/booru_api.dart';
import '../../widgets/notifiers/tag_manager.dart';
import '../../widgets/search_launch_grid.dart';
import 'package:gallery/src/db/isar.dart' as db;

import '../settings.dart';

import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:url_launcher/url_launcher.dart';

import 'secondary.dart';

class MainBooruGrid extends StatefulWidget {
  const MainBooruGrid({super.key});

  @override
  State<MainBooruGrid> createState() => _MainBooruGridState();
}

class _MainBooruGridState extends State<MainBooruGrid>
    with SearchLaunchGrid<Post> {
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  int? currentSkipped;

  late final BooruAPI api;
  late final TagManager tagManager;
  late final Isar mainGrid;
  late final StateRestoration restore;

  final downloader = Downloader();
  bool reachedEnd = false;

  final state = GridSkeletonState<Post>(index: kBooruGridDrawerIndex);

  @override
  void initState() {
    super.initState();

    mainGrid = IsarDbsOpen.primaryGrid(state.settings.selectedBooru);
    restore = StateRestoration(
        mainGrid, state.settings.selectedBooru.string, () => api.currentPage);
    api = BooruAPI.fromSettings(page: restore.copy.page);

    tagManager = TagManager(restore, (fire, f) {
      return mainGrid.tags.watchLazy(fireImmediately: fire).listen((event) {
        f();
      });
    });

    searchHook(SearchLaunchGridData(
        mainFocus: state.mainFocus,
        searchText: "",
        addItems: null,
        restorable: true));

    if (api.wouldBecomeStale &&
        state.settings.autoRefresh &&
        state.settings.autoRefreshMicroseconds != 0 &&
        restore.copy.time.isBefore(DateTime.now()
            .subtract(state.settings.autoRefreshMicroseconds.microseconds))) {
      mainGrid.writeTxnSync(() => mainGrid.posts.clearSync());
      // _clearAndRefresh();
      restore.updateTime();
    }

    settingsWatcher = db.settingsIsar().settings.watchObject(0).listen((event) {
      state.settings = event!;

      setState(() {});
    });

    favoritesWatcher = db
        .settingsIsar()
        .favoriteBoorus
        .watchLazy(fireImmediately: false)
        .listen((event) {
      state.gridKey.currentState?.imageViewKey.currentState?.setState(() {});
      setState(() {});
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();
    favoritesWatcher.cancel();

    mainGrid.close().then((value) => restartOver());

    disposeSearch();

    state.dispose();

    api.close();

    super.dispose();
  }

  Future<int> _clearAndRefresh() async {
    try {
      final list = await api.page(0, "", tagManager.excluded);
      restore.updateScrollPosition(0);
      currentSkipped = list.$2;
      await mainGrid.writeTxn(() {
        mainGrid.posts.clear();
        return mainGrid.posts.putAllByFileUrl(list.$1);
      });

      reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return mainGrid.posts.count();
  }

  Future<void> _download(int i) async {
    final p = mainGrid.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    PostTags().addTagsPost(p.filename(), p.tags, true);

    return downloader
        .add(File.d(p.fileDownloadUrl(), api.booru.url, p.filename()));
  }

  Future<int> _addLast() async {
    if (reachedEnd) {
      return mainGrid.posts.countSync();
    }
    final p = mainGrid.posts.getSync(mainGrid.posts.countSync());
    if (p == null) {
      return mainGrid.posts.countSync();
    }

    try {
      final list = await api.fromPost(
          currentSkipped != null && currentSkipped! < p.id
              ? currentSkipped!
              : p.id,
          "",
          tagManager.excluded);
      if (list.$1.isEmpty && currentSkipped == null) {
        reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = mainGrid.posts.countSync();
        mainGrid
            .writeTxnSync(() => mainGrid.posts.putAllByFileUrlSync(list.$1));
        if (mainGrid.posts.countSync() - oldCount < 3) {
          return await _addLast();
        }
      }
    } catch (e, trace) {
      log("_addLast on grid ${state.settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return mainGrid.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewPaddingOf(context);

    return BooruAPINotifier(
        api: api,
        child: TagManagerNotifier(
            tagManager: tagManager,
            child: Builder(
              builder: (context) {
                return makeGridSkeleton(
                    context,
                    state,
                    CallbackGrid<Post>(
                      key: state.gridKey,
                      systemNavigationInsets: insets,
                      registerNotifiers: [
                        (child) => TagManagerNotifier(
                            tagManager: tagManager, child: child),
                        (child) => BooruAPINotifier(api: api, child: child),
                      ],
                      addIconsImage: (post) => [
                        BooruGridActions.favorites(context, post),
                        BooruGridActions.download(context, api)
                      ],
                      onExitImageView: () =>
                          restore.removeScrollTagsSelectedPost(),
                      description: GridDescription(
                        kBooruGridDrawerIndex,
                        [
                          BooruGridActions.download(context, api),
                          BooruGridActions.favorites(context, null,
                              showDeleteSnackbar: true)
                        ],
                        state.settings.picturesPerRow,
                        listView: state.settings.booruListView,
                        keybindsDescription:
                            AppLocalizations.of(context)!.booruGridPageName,
                      ),
                      hasReachedEnd: () => reachedEnd,
                      mainFocus: state.mainFocus,
                      scaffoldKey: state.scaffoldKey,
                      onError: (error) {
                        return OutlinedButton(
                          onPressed: () {
                            launchUrl(Uri.https(api.booru.url),
                                mode: LaunchMode.externalApplication);
                          },
                          child:
                              Text(AppLocalizations.of(context)!.openInBrowser),
                        );
                      },
                      aspectRatio: state.settings.ratio.value,
                      getCell: (i) => mainGrid.posts.getSync(i + 1)!,
                      loadNext: _addLast,
                      refresh: _clearAndRefresh,
                      hideShowFab: (
                              {required bool fab, required bool foreground}) =>
                          state.updateFab(setState,
                              fab: fab, foreground: foreground),
                      hideAlias: true,
                      download: _download,
                      updateScrollPosition: restore.updateScrollPosition,
                      initalScrollPosition: restore.copy.scrollPositionGrid,
                      initalCellCount: mainGrid.posts.countSync(),
                      beforeImageViewRestore: () {
                        final last = restore.last();
                        if (last != null) {
                          WidgetsBinding.instance
                              .scheduleFrameCallback((timeStamp) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return SecondaryBooruGrid(
                                  restore: last,
                                  noRestoreOnBack: false,
                                  api: BooruAPI.fromEnum(api.booru),
                                  tagManager: tagManager,
                                  instance: IsarDbsOpen.secondaryGridName(
                                      last.copy.name),
                                );
                              },
                            ));
                          });
                        }
                      },
                      searchWidget: SearchAndFocus(
                          searchWidget(context, hint: api.booru.name),
                          searchFocus, onPressed: () {
                        if (currentlyHighlightedTag != "") {
                          state.mainFocus.unfocus();
                          tagManager.onTagPressed(
                              context,
                              Tag.string(tag: currentlyHighlightedTag),
                              api.booru,
                              true);
                        }
                      }),
                      pageViewScrollingOffset: restore.copy.scrollPositionTags,
                      initalCell: restore.copy.selectedPost,
                    ),
                    overrideBooru: api.booru,
                    popSenitel: false);
              },
            )));
  }
}

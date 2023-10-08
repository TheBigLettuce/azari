// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/pages/booru/main.dart';
import 'package:gallery/src/db/schemas/favorite_booru.dart';
import 'package:gallery/src/db/schemas/grid_state_booru.dart';
import 'package:gallery/src/db/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/grid/actions/booru_grid.dart';
import '../../net/downloader.dart';
import '../../interfaces/booru.dart';
import '../../db/post_tags.dart';
import '../../db/initalize_db.dart';
import '../../db/state_restoration.dart';
import '../../db/schemas/download_file.dart';
import '../../db/schemas/post.dart';
import '../../db/schemas/settings.dart';
import '../../widgets/search_bar/search_launch_grid_data.dart';
import '../../widgets/skeletons/grid_skeleton_state.dart';
import '../../widgets/skeletons/make_grid_skeleton.dart';
import '../../widgets/notifiers/booru_api.dart';
import '../../widgets/notifiers/tag_manager.dart';
import '../../widgets/search_bar/search_launch_grid.dart';
import '../../widgets/grid/callback_grid.dart';

class RandomBooruGrid extends StatefulWidget {
  final BooruAPI api;
  final String tags;
  final TagManager tagManager;
  final GridStateBooru? state;

  const RandomBooruGrid(
      {super.key,
      required this.api,
      required this.tagManager,
      this.state,
      required this.tags});

  @override
  State<RandomBooruGrid> createState() => _RandomBooruGridState();
}

class _RandomBooruGridState extends State<RandomBooruGrid>
    with SearchLaunchGrid<Post> {
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  (double, double?, int?)? _currentScroll;

  int? currentSkipped;

  bool reachedEnd = false;
  bool addedToBookmarks = false;

  late final Isar instance = widget.state != null
      ? DbsOpen.secondaryGridName(widget.state!.name)
      : DbsOpen.secondaryGrid(temporary: true);

  late final state = GridSkeletonState<Post>();

  @override
  void initState() {
    super.initState();

    searchHook(SearchLaunchGridData(
        mainFocus: state.mainFocus,
        searchText: widget.tags,
        addItems: null,
        restorable: false));

    settingsWatcher = Settings.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    favoritesWatcher = Dbs.g.main.favoriteBoorus
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

    widget.api.close();

    disposeSearch();

    state.dispose();

    if (addedToBookmarks && widget.state == null) {
      instance.close(deleteFromDisk: false);
      final f = File.fromUri(
          Uri.file(joinAll([Dbs.g.temporaryDbDir, "${instance.name}.isar"])));
      f.renameSync(joinAll([Dbs.g.appStorageDir, "${instance.name}.isar"]));
      Dbs.g.main.writeTxnSync(() => Dbs.g.main.gridStateBoorus.putSync(
          GridStateBooru(widget.api.booru,
              tags: widget.tags,
              page: widget.api.currentPage,
              scrollPositionTags: _currentScroll!.$2,
              selectedPost: _currentScroll!.$3,
              scrollPositionGrid: _currentScroll!.$1,
              name: instance.name,
              time: DateTime.now())));
    } else {
      instance.close(deleteFromDisk: widget.state != null ? false : true);
    }

    super.dispose();
  }

  Future<int> _clearAndRefresh() async {
    try {
      final list =
          await widget.api.page(0, widget.tags, widget.tagManager.excluded);
      currentSkipped = list.$2;
      await instance.writeTxn(() {
        instance.posts.clear();
        return instance.posts.putAllByFileUrl(list.$1);
      });

      reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return instance.posts.count();
  }

  Future<void> _download(int i) async {
    final p = instance.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    PostTags.g.addTagsPost(p.filename(), p.tags, true);

    return Downloader.g.add(
        DownloadFile.d(
            url: p.fileDownloadUrl(),
            site: widget.api.booru.url,
            name: p.filename(),
            thumbUrl: p.previewUrl),
        state.settings);
  }

  Future<int> _addLast() async {
    if (reachedEnd) {
      return instance.posts.countSync();
    }
    final p = instance.posts.getSync(instance.posts.countSync());
    if (p == null) {
      return instance.posts.countSync();
    }

    try {
      final list = await widget.api.fromPost(
          currentSkipped != null && currentSkipped! < p.id
              ? currentSkipped!
              : p.id,
          widget.tags,
          widget.tagManager.excluded);
      if (list.$1.isEmpty && currentSkipped == null) {
        reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = instance.posts.countSync();
        instance
            .writeTxnSync(() => instance.posts.putAllByFileUrlSync(list.$1));
        if (instance.posts.countSync() - oldCount < 3) {
          return await _addLast();
        }
      }
    } catch (e, trace) {
      log("_addLast on grid ${state.settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return instance.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BooruAPINotifier(
          api: widget.api,
          child: TagManagerNotifier(
              tagManager: widget.tagManager,
              child: Builder(
                builder: (context) {
                  return makeGridSkeleton(
                    context,
                    state,
                    CallbackGrid<Post>(
                      key: state.gridKey,
                      hideShowNavBar: (hide) {},
                      systemNavigationInsets:
                          MediaQuery.of(context).systemGestureInsets,
                      registerNotifiers: [
                        (child) => TagManagerNotifier(
                            tagManager: widget.tagManager, child: child),
                        (child) =>
                            BooruAPINotifier(api: widget.api, child: child),
                      ],
                      menuButtonItems: [
                        if (widget.state == null)
                          MainBooruGrid.bookmarkButton(context, state, () {
                            addedToBookmarks = true;
                          }),
                        MainBooruGrid.gridButton(state.settings)
                      ],
                      addIconsImage: (post) => [
                        BooruGridActions.favorites(context, post),
                        BooruGridActions.download(context, widget.api)
                      ],
                      description: GridDescription(
                        [
                          BooruGridActions.download(context, widget.api),
                          BooruGridActions.favorites(context, null,
                              showDeleteSnackbar: true)
                        ],
                        state.settings.booru.columns,
                        listView: state.settings.booru.listView,
                        keybindsDescription:
                            AppLocalizations.of(context)!.booruGridPageName,
                      ),
                      hasReachedEnd: () => reachedEnd,
                      mainFocus: state.mainFocus,
                      inlineMenuButtonItems: true,
                      scaffoldKey: state.scaffoldKey,
                      onError: (error) {
                        return OutlinedButton(
                          onPressed: () {
                            launchUrl(Uri.https(widget.api.booru.url),
                                mode: LaunchMode.externalApplication);
                          },
                          child:
                              Text(AppLocalizations.of(context)!.openInBrowser),
                        );
                      },
                      aspectRatio: state.settings.booru.aspectRatio.value,
                      getCell: (i) => instance.posts.getSync(i + 1)!,
                      loadNext: _addLast,
                      refresh: _clearAndRefresh,
                      onBack: () => Navigator.pop(context),
                      hideAlias: true,
                      download: _download,
                      initalCell: widget.state?.selectedPost,
                      initalCellCount:
                          widget.state != null ? instance.posts.countSync() : 0,
                      updateScrollPosition: widget.state != null
                          ? (pos, {infoPos, selectedCell}) {
                              final prev = Dbs.g.main.gridStateBoorus
                                  .getByNameSync(widget.state!.name)!;

                              Dbs.g.main.writeTxnSync(() => Dbs
                                  .g.main.gridStateBoorus
                                  .putByNameSync(prev.copy(true,
                                      scrollPositionGrid: pos,
                                      scrollPositionTags: infoPos,
                                      page: widget.api.currentPage,
                                      selectedPost: selectedCell)));
                            }
                          : (pos, {infoPos, selectedCell}) {
                              _currentScroll = (pos, infoPos, selectedCell);
                            },
                      pageViewScrollingOffset: widget.state?.scrollPositionTags,
                      initalScrollPosition:
                          widget.state?.scrollPositionGrid ?? 0,
                      searchWidget: SearchAndFocus(
                          searchWidget(context, hint: widget.api.booru.name),
                          searchFocus, onPressed: () {
                        if (currentlyHighlightedTag != "") {
                          state.mainFocus.unfocus();
                          widget.tagManager.onTagPressed(
                              context,
                              Tag.string(tag: currentlyHighlightedTag),
                              widget.api.booru,
                              true);
                        }
                      }),
                    ),
                    overrideBooru: widget.api.booru,
                  );
                },
              ))),
    );
  }
}

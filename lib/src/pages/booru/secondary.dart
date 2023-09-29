// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
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

import '../settings.dart';

import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class SecondaryBooruGrid extends StatefulWidget {
  final StateRestoration restore;
  final Isar instance;
  final TagManager tagManager;
  final BooruAPI api;

  final bool noRestoreOnBack;

  const SecondaryBooruGrid(
      {super.key,
      required this.restore,
      required this.instance,
      required this.api,
      required this.noRestoreOnBack,
      required this.tagManager});

  @override
  State<SecondaryBooruGrid> createState() => _SecondaryBooruGridState();
}

class _SecondaryBooruGridState extends State<SecondaryBooruGrid>
    with SearchLaunchGrid<Post> {
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  int? currentSkipped;

  bool reachedEnd = false;
  bool addedToBookmarks = false;

  late final state = GridSkeletonState<Post>(index: kBooruGridDrawerIndex);

  @override
  void initState() {
    super.initState();

    searchHook(SearchLaunchGridData(
        mainFocus: state.mainFocus,
        searchText: widget.restore.copy.tags,
        addItems: null,
        restorable: true));

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

    if (addedToBookmarks) {
      widget.instance.close(deleteFromDisk: false);
      widget.restore.moveToBookmarks(widget.api.booru);
    } else {
      if (!isRestart) {
        widget.instance.close(deleteFromDisk: true);
        widget.restore.removeSelf();
      } else {
        widget.instance.close(deleteFromDisk: false);
      }
    }

    super.dispose();
  }

  Future<int> _clearAndRefresh() async {
    try {
      final list = await widget.api
          .page(0, widget.restore.copy.tags, widget.tagManager.excluded);
      widget.restore.updateScrollPosition(0);
      currentSkipped = list.$2;
      await widget.instance.writeTxn(() {
        widget.instance.posts.clear();
        return widget.instance.posts.putAllByFileUrl(list.$1);
      });

      reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return widget.instance.posts.count();
  }

  Future<void> _download(int i) async {
    final p = widget.instance.posts.getSync(i + 1);
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
      return widget.instance.posts.countSync();
    }
    final p = widget.instance.posts.getSync(widget.instance.posts.countSync());
    if (p == null) {
      return widget.instance.posts.countSync();
    }

    try {
      final list = await widget.api.fromPost(
          currentSkipped != null && currentSkipped! < p.id
              ? currentSkipped!
              : p.id,
          widget.restore.copy.tags,
          widget.tagManager.excluded);
      if (list.$1.isEmpty && currentSkipped == null) {
        reachedEnd = true;
      } else {
        currentSkipped = list.$2;
        final oldCount = widget.instance.posts.countSync();
        widget.instance.writeTxnSync(
            () => widget.instance.posts.putAllByFileUrlSync(list.$1));
        if (widget.instance.posts.countSync() - oldCount < 3) {
          return await _addLast();
        }
      }
    } catch (e, trace) {
      log("_addLast on grid ${state.settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return widget.instance.posts.count();
  }

  void _restore(BuildContext context) {
    Navigator.pop(context);
    if (widget.noRestoreOnBack) {
      return;
    }

    final next = widget.restore.next();
    if (next != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) {
          return SecondaryBooruGrid(
            restore: next,
            noRestoreOnBack: false,
            api: BooruAPI.fromEnum(widget.api.booru),
            tagManager: widget.tagManager,
            instance: IsarDbsOpen.secondaryGridName(next.copy.name),
          );
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewPaddingOf(context);

    return BooruAPINotifier(
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
                    systemNavigationInsets: insets,
                    registerNotifiers: [
                      (child) => TagManagerNotifier(
                          tagManager: widget.tagManager, child: child),
                      (child) =>
                          BooruAPINotifier(api: widget.api, child: child),
                    ],
                    menuButtonItems: [
                      IconButton(
                          onPressed: () {
                            addedToBookmarks = true;
                            ScaffoldMessenger.of(state.gridKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text(
                              "Bookmarked", // TODO: change
                            )));
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.bookmark_add)),
                      MainBooruGrid.gridButton(state.settings)
                    ],
                    addIconsImage: (post) => [
                      BooruGridActions.favorites(context, post),
                      BooruGridActions.download(context, widget.api)
                    ],
                    onExitImageView: () =>
                        widget.restore.removeScrollTagsSelectedPost(),
                    description: GridDescription(
                      kBooruGridDrawerIndex,
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
                    inlineMenuButtonItems: true,
                    hasReachedEnd: () => reachedEnd,
                    mainFocus: state.mainFocus,
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
                    backButtonBadge: widget.restore.secondaryCount(),
                    getCell: (i) => widget.instance.posts.getSync(i + 1)!,
                    loadNext: _addLast,
                    refresh: _clearAndRefresh,
                    initalCellCount: widget.instance.posts.countSync(),
                    hideShowFab: (
                            {required bool fab, required bool foreground}) =>
                        state.updateFab(setState,
                            fab: fab, foreground: foreground),
                    onBack: () {
                      _restore(context);
                    },
                    hideAlias: true,
                    download: _download,
                    updateScrollPosition: widget.restore.updateScrollPosition,
                    initalScrollPosition:
                        widget.restore.copy.scrollPositionGrid,
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
                    pageViewScrollingOffset:
                        widget.restore.copy.scrollPositionTags,
                    initalCell: widget.restore.copy.selectedPost,
                  ),
                  overrideBooru: widget.api.booru,
                  overrideOnPop: () {
                    _restore(context);
                    return Future.value(false);
                  },
                );
              },
            )));
  }
}

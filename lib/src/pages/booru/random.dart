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
import 'package:gallery/src/db/isar.dart' as db;

import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:url_launcher/url_launcher.dart';

class RandomBooruGrid extends StatefulWidget {
  final BooruAPI api;
  final String tags;
  final TagManager tagManager;
  const RandomBooruGrid(
      {super.key,
      required this.api,
      required this.tagManager,
      required this.tags});

  @override
  State<RandomBooruGrid> createState() => _RandomBooruGridState();
}

class _RandomBooruGridState extends State<RandomBooruGrid>
    with SearchLaunchGrid<Post> {
  late final StreamSubscription<Settings?> settingsWatcher;
  late final StreamSubscription favoritesWatcher;

  int? currentSkipped;

  final downloader = Downloader();
  bool reachedEnd = false;

  final Isar instance = IsarDbsOpen.secondaryGrid(temporary: true);

  late final state = GridSkeletonState<Post>(index: kBooruGridDrawerIndex);

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

    widget.api.close();

    disposeSearch();

    state.dispose();

    instance.close(deleteFromDisk: true);

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

    PostTags().addTagsPost(p.filename(), p.tags, true);

    return downloader
        .add(File.d(p.fileDownloadUrl(), widget.api.booru.url, p.filename()));
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
                      addIconsImage: (post) => [
                        BooruGridActions.favorites(post),
                        BooruGridActions.download(context, widget.api)
                      ],
                      description: GridDescription(
                        kBooruGridDrawerIndex,
                        [
                          BooruGridActions.download(context, widget.api),
                          BooruGridActions.favorites(null)
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
                            launchUrl(Uri.https(widget.api.booru.url),
                                mode: LaunchMode.externalApplication);
                          },
                          child:
                              Text(AppLocalizations.of(context)!.openInBrowser),
                        );
                      },
                      aspectRatio: state.settings.ratio.value,
                      getCell: (i) => instance.posts.getSync(i + 1)!,
                      loadNext: _addLast,
                      refresh: _clearAndRefresh,
                      hideShowFab: (
                              {required bool fab, required bool foreground}) =>
                          state.updateFab(setState,
                              fab: fab, foreground: foreground),
                      onBack: () => Navigator.pop(context),
                      hideAlias: true,
                      download: _download,
                      initalScrollPosition: 0,
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
                    popSenitel: false);
              },
            )));
  }
}

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
import 'package:gallery/src/booru/downloader/downloader.dart';
import 'package:gallery/src/db/isar.dart' as db;
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../booru/interface.dart';
import '../db/isar.dart';
import '../schemas/download_file.dart';
import '../schemas/settings.dart';
import '../booru/tags/tags.dart';
import '../widgets/notifiers/booru_api.dart';
import '../widgets/notifiers/grid_tab.dart';
import '../widgets/search_launch_grid.dart';

class BooruScroll extends StatefulWidget {
  final GridTab grids;
  final String tags;
  final double initalScroll;
  final bool clear;
  final int? booruPage;
  final double? pageViewScrollingOffset;
  final int? initalPost;
  final bool toRestore;
  final DateTime? time;

  final Isar? currentInstance;
  final bool isPrimary;
  final bool closeGrids;
  final BooruAPI? api;
  final bool forceCloseApi;

  const BooruScroll.primary({
    super.key,
    required this.initalScroll,
    required this.grids,
    required this.time,
    required this.booruPage,
    this.clear = false,
  })  : tags = "",
        toRestore = false,
        closeGrids = false,
        api = null,
        forceCloseApi = false,
        pageViewScrollingOffset = null,
        initalPost = null,
        currentInstance = null,
        isPrimary = true;

  const BooruScroll.secondary({
    super.key,
    required this.grids,
    required Isar instance,
    required this.tags,
    this.forceCloseApi = false,
    this.closeGrids = false,
    this.api,
  })  : initalScroll = 0,
        clear = true,
        toRestore = false,
        booruPage = null,
        pageViewScrollingOffset = null,
        initalPost = null,
        time = null,
        currentInstance = instance,
        isPrimary = false;

  const BooruScroll.restore(
      {super.key,
      required this.grids,
      required Isar instance,
      required this.pageViewScrollingOffset,
      required this.initalPost,
      required this.tags,
      required this.booruPage,
      required this.initalScroll})
      : clear = false,
        toRestore = true,
        api = null,
        forceCloseApi = false,
        closeGrids = false,
        currentInstance = instance,
        time = null,
        isPrimary = false;

  @override
  State<BooruScroll> createState() => BooruScrollState();
}

class BooruScrollState extends State<BooruScroll> with SearchLaunchGrid {
  late final StreamSubscription<Settings?> settingsWatcher;
  late final void Function(double pos, {double? infoPos, int? selectedCell})
      updateScrollPosition;

  Downloader downloader = Downloader();
  bool reachedEnd = false;

  late final GridSkeletonState skeletonState = GridSkeletonState(
      index: kBooruGridDrawerIndex,
      onWillPop: () {
        if (widget.isPrimary) {
          if (widget.toRestore) {
            widget.grids
                .restoreStateNext(context, widget.currentInstance!.name);
          }
        }

        return Future.value(true);
      });

  @override
  void initState() {
    super.initState();

    booru = widget.api ?? BooruAPI.fromSettings(page: widget.booruPage);

    searchHook(SearchLaunchGridData(skeletonState.mainFocus, widget.tags));

    if (widget.isPrimary) {
      updateScrollPosition = (pos, {double? infoPos, int? selectedCell}) =>
          widget.grids
              .updateScroll(booru, pos, booru.currentPage, tagPos: infoPos);
    } else {
      updateScrollPosition = (pos, {double? infoPos, int? selectedCell}) =>
          widget.grids.updateScrollSecondary(
              widget.currentInstance!, pos, widget.tags, booru.currentPage,
              scrollPositionTags: infoPos, selectedPost: selectedCell);
    }

    if (widget.clear) {
      if (widget.isPrimary) {
        widget.grids.instance
            .writeTxnSync(() => widget.grids.instance.posts.clearSync());
      } else {
        widget.currentInstance!
            .writeTxnSync(() => widget.currentInstance!.posts.clearSync());
      }
    }

    if (skeletonState.settings.autoRefresh &&
        skeletonState.settings.autoRefreshMicroseconds != 0 &&
        widget.time != null &&
        widget.time!.isBefore(DateTime.now().subtract(
            skeletonState.settings.autoRefreshMicroseconds.microseconds))) {
      _getInstance().writeTxnSync(() => _getInstance().posts.clearSync());
      _clearAndRefresh();
    }

    settingsWatcher = db.settingsIsar().settings.watchObject(0).listen((event) {
      skeletonState.settings = event!;

      setState(() {});
    });
  }

  @override
  void dispose() {
    settingsWatcher.cancel();

    if (!widget.isPrimary) {
      widget.grids.removeSecondaryGrid(widget.currentInstance!.name);
    } else {
      widget.grids.close();
    }

    disposeSearch();

    skeletonState.dispose();

    if (widget.isPrimary || widget.forceCloseApi) {
      booru.close();
    }

    if (widget.closeGrids) {
      widget.grids.close();
    }

    super.dispose();
  }

  Isar _getInstance() =>
      widget.isPrimary ? widget.grids.instance : widget.currentInstance!;

  Future<int> _clearAndRefresh() async {
    final instance = _getInstance();

    booru;

    try {
      final list = await booru.page(0, widget.tags, widget.grids.excluded);
      updateScrollPosition(0);
      await instance.writeTxn(() {
        instance.posts.clear();
        return instance.posts.putAllById(list);
      });

      reachedEnd = false;
    } catch (e) {
      rethrow;
    }

    return instance.posts.count();
  }

  Future<void> _download(int i) async {
    final instance = _getInstance();

    final p = instance.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    PostTags().addTagsPost(p.filename(), p.tags.split(" "), true);

    return downloader
        .add(File.d(p.fileDownloadUrl(), booru.booru.url, p.filename()));
  }

  Future<int> _addLast() async {
    final instance = _getInstance();

    if (reachedEnd) {
      return instance.posts.countSync();
    }
    final p = instance.posts.getSync(instance.posts.countSync());
    if (p == null) {
      return instance.posts.countSync();
    }

    try {
      final list =
          await booru.fromPost(p.id, widget.tags, widget.grids.excluded);
      if (list.isEmpty) {
        reachedEnd = true;
      } else {
        final oldCount = instance.posts.countSync();
        instance.writeTxnSync(() => instance.posts.putAllByIdSync(list));
        if (instance.posts.countSync() - oldCount < 3) {
          return await _addLast();
        }
      }
    } catch (e, trace) {
      log("_addLast on grid ${skeletonState.settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return instance.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewPaddingOf(context);

    return BooruAPINotifier(
        api: booru,
        child: GridTabNotifier(
            tab: widget.grids,
            child: Builder(
              builder: (context) {
                return makeGridSkeleton(
                    context,
                    skeletonState,
                    CallbackGrid<Post>(
                      key: skeletonState.gridKey,
                      systemNavigationInsets: insets,
                      registerNotifiers: [
                        (child) =>
                            GridTabNotifier(tab: widget.grids, child: child),
                        (child) => BooruAPINotifier(api: booru, child: child)
                      ],
                      description: GridDescription(
                        kBooruGridDrawerIndex,
                        [
                          GridBottomSheetAction(Icons.download, (selected) {
                            for (final element in selected) {
                              PostTags().addTagsPost(element.filename(),
                                  element.tags.split(" "), true);
                              downloader.add(File.d(element.fileUrl,
                                  booru.booru.url, element.filename()));
                            }
                          },
                              true,
                              GridBottomSheetActionExplanation(
                                label: AppLocalizations.of(context)!
                                    .downloadActionLabel,
                                body: AppLocalizations.of(context)!
                                    .downloadActionBody,
                              ))
                        ],
                        skeletonState.settings.picturesPerRow,
                        listView: skeletonState.settings.booruListView,
                        keybindsDescription:
                            AppLocalizations.of(context)!.booruGridPageName,
                      ),
                      hasReachedEnd: () => reachedEnd,
                      mainFocus: skeletonState.mainFocus,
                      scaffoldKey: skeletonState.scaffoldKey,
                      onError: (error) {
                        return OutlinedButton(
                          onPressed: () {
                            launchUrl(Uri.https(booru.booru.url),
                                mode: LaunchMode.externalApplication);
                          },
                          child:
                              Text(AppLocalizations.of(context)!.openInBrowser),
                        );
                      },
                      aspectRatio: skeletonState.settings.ratio.value,
                      getCell: (i) => _getInstance().posts.getSync(i + 1)!,
                      cloudflareHook: () {
                        return CloudflareBlockInterface(booru);
                      },
                      loadNext: _addLast,
                      refresh: _clearAndRefresh,
                      hideShowFab: (
                              {required bool fab, required bool foreground}) =>
                          skeletonState.updateFab(setState,
                              fab: fab, foreground: foreground),
                      onBack: widget.tags.isEmpty
                          ? null
                          : () {
                              if (widget.toRestore) {
                                widget.grids.restoreStateNext(
                                    context, widget.currentInstance!.name);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                      hideAlias: true,
                      download: _download,
                      updateScrollPosition: updateScrollPosition,
                      initalScrollPosition: widget.initalScroll,
                      initalCellCount:
                          widget.clear ? 0 : _getInstance().posts.countSync(),
                      searchWidget: SearchAndFocus(
                          searchWidget(context, hint: booru.booru.name),
                          searchFocus, onPressed: () {
                        if (currentlyHighlightedTag != "") {
                          skeletonState.mainFocus.unfocus();
                          widget.grids.onTagPressed(context,
                              Tag.string(tag: currentlyHighlightedTag), booru);
                        }
                      }),
                      pageViewScrollingOffset: widget.pageViewScrollingOffset,
                      initalCell: widget.initalPost,
                    ),
                    overrideBooru: booru.booru);
              },
            )));
  }
}

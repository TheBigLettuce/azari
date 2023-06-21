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
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/db/isar.dart' as db;
import 'package:gallery/src/widgets/drawer/drawer.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as sc_pos;
import 'package:gallery/src/schemas/tags.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path/path.dart' as path;

import '../schemas/download_file.dart';
import '../schemas/secondary_grid.dart';
import '../schemas/settings.dart';
import '../booru/tags/tags.dart';

void _updateScrollPrimary(BooruAPI booru, double pos, int? page,
    {double? tagPos}) {
  db.isar().writeTxnSync(() => db.isar().scrollPositionPrimarys.putSync(
      sc_pos.ScrollPositionPrimary(pos, booru.domain,
          page: page, tagPos: tagPos)));
}

void _updateScrollSecondary(Isar isar, double pos, String tags, int? page,
    {int? selectedPost, double? scrollPositionTags}) {
  isar.writeTxnSync(() => isar.secondaryGrids.putSync(
      SecondaryGrid(tags, scrollPositionTags, selectedPost, pos, page: page)));
}

class BooruScroll extends StatefulWidget {
  final Isar isar;
  final String tags;
  final double initalScroll;
  final bool clear;
  final int? booruPage;
  final double? pageViewScrollingOffset;
  final int? initalPost;
  final bool toRestore;
  final DateTime? time;

  // ignore: unused_field
  final String _type; // for debug only

  final void Function(String path)? closeDb;

  const BooruScroll.primary({
    super.key,
    required this.initalScroll,
    required this.isar,
    required this.time,
    this.clear = false,
  })  : tags = "",
        toRestore = false,
        booruPage = null,
        pageViewScrollingOffset = null,
        initalPost = null,
        closeDb = null,
        _type = "primary";

  const BooruScroll.secondary({
    super.key,
    required this.isar,
    required this.tags,
  })  : initalScroll = 0,
        clear = true,
        toRestore = false,
        booruPage = null,
        pageViewScrollingOffset = null,
        initalPost = null,
        time = null,
        closeDb = db.removeSecondaryGrid,
        _type = "secondary";

  const BooruScroll.restore(
      {super.key,
      required this.isar,
      required this.pageViewScrollingOffset,
      required this.initalPost,
      required this.tags,
      required this.booruPage,
      required this.initalScroll})
      : clear = false,
        toRestore = true,
        time = null,
        closeDb = db.removeSecondaryGrid,
        _type = "restore";

  @override
  State<BooruScroll> createState() => _BooruScrollState();
}

class _BooruScrollState extends State<BooruScroll> {
  late BooruAPI booru = db.getBooru(page: widget.booruPage);
  late Isar isar = widget.isar;
  late StreamSubscription<void> tagWatcher;
  late StreamSubscription<Settings?> settingsWatcher;
  List<String> tags = BooruTags().latest.getStrings();
  late final void Function(double pos, {double? infoPos, int? selectedCell})
      updateScrollPosition;
  Downloader downloader = Downloader();
  bool reachedEnd = false;

  late GridSkeletonState skeletonState = GridSkeletonState(
      index: kBooruGridDrawerIndex,
      onWillPop: () {
        if (widget.tags.isNotEmpty) {
          if (widget.toRestore) {
            db.restoreStateNext(context, isar.name);
          }
        }

        return Future.value(true);
      });

  @override
  void initState() {
    super.initState();

    if (widget.tags.isEmpty) {
      updateScrollPosition = (pos, {double? infoPos, int? selectedCell}) =>
          _updateScrollPrimary(booru, pos, booru.currentPage, tagPos: infoPos);
    } else {
      updateScrollPosition = (pos, {double? infoPos, int? selectedCell}) =>
          _updateScrollSecondary(
              widget.isar, pos, widget.tags, booru.currentPage,
              scrollPositionTags: infoPos, selectedPost: selectedCell);
    }

    if (widget.clear) {
      isar.writeTxnSync(() => isar.posts.clearSync());
    }

    tagWatcher = db.isar().lastTags.watchLazy().listen((_) {
      tags = BooruTags().latest.getStrings();
    });

    settingsWatcher = db.isar().settings.watchObject(0).listen((event) {
      skeletonState.settings = event!;

      setState(() {});
    });
  }

  @override
  void dispose() {
    tagWatcher.cancel();
    settingsWatcher.cancel();

    if (widget.closeDb != null) {
      widget.closeDb!(isar.name);
    }

    skeletonState.dispose();

    booru.close();

    super.dispose();
  }

  List<String> _searchFilter(String value) => value.isEmpty
      ? []
      : tags.where((element) => element.contains(value)).toList();

  Future<int> _clearAndRefresh() async {
    try {
      var list = await booru.page(0, widget.tags);
      updateScrollPosition(0);
      await isar.writeTxn(() {
        isar.posts.clear();
        return isar.posts.putAllById(list);
      });
      BooruTags().addAllPostTags(list);
      reachedEnd = false;
    } catch (e, trace) {
      log("refreshing grid on ${skeletonState.settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return isar.posts.count();
  }

  void _search(String t) => BooruTags().onPressed(context, t);

  Future<void> _download(int i) async {
    var p = isar.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    return downloader.add(File.d(p.downloadUrl(), booru.domain, p.filename()));
  }

  Future<int> _addLast() async {
    if (reachedEnd) {
      return isar.posts.countSync();
    }
    var p = isar.posts.getSync(isar.posts.countSync());
    if (p == null) {
      return isar.posts.countSync();
    }

    try {
      var list = await booru.fromPost(p.id, widget.tags);
      if (list.isEmpty) {
        reachedEnd = true;
      } else {
        isar.writeTxnSync(() => isar.posts.putAllByIdSync(list));
        BooruTags().addAllPostTags(list);
      }
    } catch (e, trace) {
      log("_addLast on grid ${skeletonState.settings.selectedBooru.string}",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }

    return isar.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.viewPaddingOf(context);

    return makeGridSkeleton(
      context,
      skeletonState,
      CallbackGrid<Post, PostShrinked>(
        key: skeletonState.gridKey,
        systemNavigationInsets: insets,
        description: GridDescription(
            kBooruGridDrawerIndex,
            AppLocalizations.of(context)!.booruGridPageName,
            [
              GridBottomSheetAction(Icons.download, (selected) {
                for (var element in selected) {
                  downloader.add(
                      File.d(element.fileUrl, booru.domain, element.fileName));
                }
              }, true)
            ],
            skeletonState.settings.picturesPerRow,
            time: booru.wouldBecomeStale ? widget.time : null),
        hasReachedEnd: () => reachedEnd,
        mainFocus: skeletonState.mainFocus,
        scaffoldKey: skeletonState.scaffoldKey,
        aspectRatio: skeletonState.settings.ratio.value,
        getCell: (i) => isar.posts.getSync(i + 1)!,
        loadNext: _addLast,
        refresh: _clearAndRefresh,
        hideShowFab: (show) => skeletonState.updateFab(setState, show),
        onBack: widget.tags.isEmpty
            ? null
            : () {
                if (widget.toRestore) {
                  db.restoreStateNext(context, isar.name);
                } else {
                  Navigator.pop(context);
                }
              },
        searchStartingValue: widget.tags,
        search: _search,
        hideAlias: true,
        download: _download,
        updateScrollPosition: updateScrollPosition,
        initalScrollPosition: widget.initalScroll,
        initalCellCount: widget.clear ? 0 : isar.posts.countSync(),
        searchFilter: _searchFilter,
        pageViewScrollingOffset: widget.pageViewScrollingOffset,
        initalCell: widget.initalPost,
      ),
    );
  }
}

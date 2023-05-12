import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/downloader.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/cell/booru.dart';
import 'package:gallery/src/db/isar.dart' as db;
import 'package:gallery/src/drawer.dart';
import 'package:gallery/src/image/cells.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as sc_pos;
import 'package:gallery/src/schemas/scroll_position_search.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

import '../schemas/download_file.dart';
import '../schemas/settings.dart';
import 'tags/tags.dart';

void _updateScrollPrimary(double pos, int? page) {
  db.isar().writeTxnSync(() => db.isar().scrollPositionPrimarys.putSync(
      sc_pos.ScrollPositionPrimary(pos, db.getBooru().domain(), page: page)));
}

void _updateScrollSecondary(double pos, String tags, int? page) {
  db.isar().writeTxnSync(() => db.isar().scrollPositionTags.putSync(
      ScrollPositionTags(pos, db.getBooru().domain(), tags, page: page)));
}

class BooruScroll extends StatefulWidget {
  final Isar isar;
  final String tags;
  final double initalScroll;
  final bool clear;
  final int? booruPage;

  const BooruScroll.primary({
    super.key,
    required this.initalScroll,
    required this.isar,
    this.clear = false,
  })  : tags = "",
        booruPage = null;

  const BooruScroll.secondary({
    super.key,
    required this.isar,
    required this.tags,
  })  : initalScroll = 0,
        clear = true,
        booruPage = null;

  const BooruScroll.restore(
      {super.key,
      required this.isar,
      required this.tags,
      required this.booruPage,
      required this.initalScroll})
      : clear = false;

  @override
  State<BooruScroll> createState() => _BooruScrollState();
}

class _BooruScrollState extends State<BooruScroll> {
  late BooruAPI booru = db.getBooru(page: widget.booruPage);
  late Isar isar = widget.isar;
  late StreamSubscription<void> tagWatcher;
  List<String> tags = BooruTags().getLatest();
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  late final void Function(double pos) updateScrollPosition;
  Downloader downloader = Downloader();
  bool reachedEnd = false;

  @override
  void initState() {
    if (widget.tags.isEmpty) {
      updateScrollPosition =
          (pos) => _updateScrollPrimary(pos, booru.currentPage());
    } else {
      updateScrollPosition = (pos) =>
          _updateScrollSecondary(pos, widget.tags, booru.currentPage());
    }

    super.initState();
    if (widget.clear) {
      isar.writeTxnSync(() => isar.posts.clearSync());
    }

    tagWatcher = db.isar().lastTags.watchLazy().listen((_) {
      tags = BooruTags().getLatest();
    });
  }

  @override
  void dispose() {
    tagWatcher.cancel();

    if (widget.tags.isNotEmpty) {
      _updateScrollSecondary(0, "", 0);
    }

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
      reachedEnd = false;
    } catch (e) {
      print(e);
    }

    return isar.posts.count();
  }

  void _search(String t) {
    BooruTags().addLatest(t);
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
      return BooruScroll.secondary(
        isar: db.isarPostsOnly(),
        tags: t,
      );
    }), ModalRoute.withName('/booru'));
  }

  Future<void> _download(int i) async {
    var p = isar.posts.getSync(i + 1);
    if (p == null) {
      return Future.value();
    }

    return downloader.add(File.d(p.fileUrl, booru.domain(), p.filename()));
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
      }
    } catch (e) {
      print(e);
    }

    return isar.posts.count();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          if (widget.tags.isNotEmpty) {
            Navigator.of(context).popUntil(ModalRoute.withName("/booru"));
          }

          return Future.value(true);
        },
        child: Scaffold(
          key: _key,
          drawer: makeDrawer(context, false),
          body: CellsWidget<BooruCell>(
            hasReachedEnd: () => reachedEnd,
            scaffoldKey: _key,
            getCell: (i) => isar.posts.getSync(i + 1)!.booruCell(_search),
            loadNext: _addLast,
            refresh: _clearAndRefresh,
            showBack: widget.tags != "",
            searchStartingValue: widget.tags,
            search: _search,
            hideAlias: true,
            onLongPress: _download,
            updateScrollPosition: updateScrollPosition,
            initalScrollPosition: widget.initalScroll,
            initalCellCount: widget.clear ? 0 : isar.posts.countSync(),
            searchFilter: _searchFilter,
          ),
        ));
  }
}

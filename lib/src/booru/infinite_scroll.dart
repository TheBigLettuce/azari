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
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

import 'tags/tags.dart';

class BooruScroll extends StatefulWidget {
  final Isar isar;
  final String tags;
  final void Function(double pos)? updateScrollPosition;
  final double initalScroll;
  final bool clear;

  const BooruScroll.primary(
      {super.key,
      required this.initalScroll,
      required this.isar,
      this.clear = false,
      this.updateScrollPosition})
      : tags = "";

  const BooruScroll.secondary(
      {super.key, required this.isar, required this.tags})
      : initalScroll = 0,
        updateScrollPosition = null,
        clear = true;

  @override
  State<BooruScroll> createState() => _BooruScrollState();
}

class _BooruScrollState extends State<BooruScroll> {
  BooruAPI booru = db.getBooru();
  late Isar isar = widget.isar;
  late StreamSubscription<void> tagWatcher;
  List<String> tags = BooruTags().getLatest();

  @override
  void initState() {
    super.initState();
    print("newState");
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

    super.dispose();
  }

  List<String> _searchFilter(String value) => value.isEmpty
      ? []
      : tags.where((element) => element.contains(value)).toList();

  Future<int> _clearAndRefresh() async {
    try {
      var list = await booru.page(0, widget.tags);
      isar.writeTxnSync(
          () => isar.scrollPositions.putSync(sc_pos.ScrollPosition(0)));
      await isar.writeTxn(() {
        isar.posts.clear();
        return isar.posts.putAllById(list);
      });
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

    return downloadFile(p.fileUrl, booru.domain(), p.filename());
  }

  Future<int> _addLast() async {
    var p = isar.posts.getSync(isar.posts.countSync());
    if (p == null) {
      return isar.posts.countSync();
    }

    try {
      var list = await booru.fromPost(p.id, widget.tags);
      isar.writeTxnSync(() => isar.posts.putAllByIdSync(list));
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
          drawer: makeDrawer(context, false),
          body: CellsWidget<BooruCell>(
            getCell: (i) => isar.posts.getSync(i + 1)!.booruCell(_search),
            loadNext: _addLast,
            refresh: _clearAndRefresh,
            showBack: widget.tags != "",
            searchStartingValue: widget.tags,
            search: _search,
            hideAlias: true,
            onLongPress: _download,
            updateScrollPosition: widget.updateScrollPosition,
            initalScrollPosition: widget.initalScroll,
            initalCellCount: widget.clear ? 0 : isar.posts.countSync(),
            searchFilter: _searchFilter,
          ),
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/downloader.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/booru/search.dart';
import 'package:gallery/src/cell/booru.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/drawer.dart';
import 'package:gallery/src/image/grid.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart' as sc_pos;
import 'package:isar/isar.dart';

class BooruScroll extends StatefulWidget {
  final Isar isar;
  final String tags;
  final void Function(double pos)? updateScrollPosition;
  final double initalScroll;

  const BooruScroll(
      {super.key,
      required this.initalScroll,
      required this.isar,
      this.tags = "",
      this.updateScrollPosition});

  @override
  State<BooruScroll> createState() => _BooruScrollState();
}

class _BooruScrollState extends State<BooruScroll> {
  BooruAPI booru = getBooru();
  late String tags = widget.tags;
  late Isar isar = widget.isar;

  Future<int> _clearAndRefresh() async {
    try {
      var list = await booru.page(0, tags);
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
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
      return BooruScroll(
        isar: isarPostsOnly(),
        tags: t,
        initalScroll: 0,
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
      var list = await booru.fromPost(p.id, tags);
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

          if (tags.isNotEmpty) {
            tags = "";
            _clearAndRefresh();
            return Future.value(false);
          }

          return Future.value(true);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(tags.isEmpty ? booru.name() : tags),
            leading: tags.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      tags = "";
                      _clearAndRefresh();
                    },
                    icon: const Icon(Icons.arrow_back))
                : null,
            actions: [
              IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return SearchBooru(onSubmitted: (t) {
                          _search(t);
                        });
                      },
                    ));
                  },
                  icon: const Icon(Icons.search))
            ],
          ),
          drawer: makeDrawer(context, false),
          body: ImageGrid<BooruCell>(
            getCell: (i) => isar.posts.getSync(i + 1)!.booruCell(_search),
            loadNext: _addLast,
            refresh: _clearAndRefresh,
            numbRow: 2,
            hideAlias: true,
            onLongPress: _download,
            updateScrollPosition: widget.updateScrollPosition,
            initalScrollPosition: widget.initalScroll,
            initalCellCount: isar.posts.countSync(),
          ),
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/search.dart';
import 'package:gallery/src/cell/boorucell.dart';
import 'package:gallery/src/drawer.dart';
import 'package:gallery/src/image/grid.dart';
import 'package:gallery/src/image/view.dart';
import 'package:gallery/src/models/directory.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import 'interface.dart';

class Booru extends StatefulWidget {
  const Booru({super.key});

  @override
  State<Booru> createState() => _BooruState();
}

class _BooruState extends State<Booru> {
  Gelbooru booru = Gelbooru();
  String tags = "";
  int currentPage = 0;
  List<Post>? posts;
  bool refreshing = true;
  bool defunct = false;

  @override
  void initState() {
    super.initState();

    booru.page(currentPage, tags).then((value) {
      if (defunct) {
        return;
      }

      setState(() {
        posts = value;
        refreshing = false;
      });
    });
  }

  @override
  void dispose() {
    defunct = true;

    super.dispose();
  }

  Future _download(int i) {
    var cell = (posts!)[i];
    return Provider.of<DirectoryModel>(context, listen: false).download(
        cell.fileUrl, "gelbooru.com", "${cell.id} - ${cell.md5}${cell.ext}");
  }

  Future _goToPage(int i) {
    if (defunct) {
      return Future.value(true);
    }

    setState(() {
      refreshing = true;
      posts = null;
    });

    return booru.page(i, tags).then((value) {
      if (defunct) {
        return Future.value(true);
      }
      setState(() {
        currentPage = i;
        posts = value;
        refreshing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(tags == "" ? currentPage.toString() : tags),
          leading: currentPage == 0
              ? null
              : IconButton(
                  onPressed: refreshing
                      ? null
                      : () {
                          if (currentPage != 0) {
                            _goToPage(currentPage - 1);
                          } else {
                            defunct = true;
                            Navigator.pop(context);
                          }
                        },
                  icon: const Icon(Icons.arrow_back),
                ),
          actions: [
            IconButton(
                onPressed: refreshing
                    ? null
                    : () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return SearchBooru(onSubmitted: (value) {
                            setState(() {
                              posts = null;
                              tags = value;
                              booru.page(0, tags).then((value) {
                                setState(() {
                                  posts = value;
                                });
                              });
                              Navigator.pop(context);
                            });
                          });
                        }));
                      },
                icon: const Icon(Icons.search)),
            IconButton(
                onPressed: refreshing
                    ? null
                    : () {
                        _goToPage(currentPage + 1);
                      },
                icon: const Icon(Icons.arrow_forward))
          ],
        ),
        drawer: makeDrawer(context, false),
        body: WillPopScope(
          onWillPop: () {
            defunct = true;
            return Future.value(true);
          },
          child: posts == null
              ? const LinearProgressIndicator()
              : ImageGrid<BooruCell>(
                  onOverscroll: () {
                    return _goToPage(currentPage);
                  },
                  hideAlias: true,
                  numbRow: 2,
                  data: postsToCells(posts!),
                  onLongPress: _download,
                  onPressed: (context, i) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return ImageView<BooruCell>(
                          download: _download,
                          startingCell: i,
                          cells: postsToCells(posts!));
                    }));
                  },
                ),
        ));
  }
}

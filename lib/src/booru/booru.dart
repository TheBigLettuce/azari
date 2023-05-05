import 'package:flutter/material.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/downloader.dart';
import 'package:gallery/src/booru/search.dart';
import 'package:gallery/src/cell/booru.dart';
import 'package:gallery/src/drawer.dart';
import 'package:gallery/src/image/grid.dart';
import '../schemas/post.dart';
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

  Future _download(int i) {
    var cell = (posts!)[i];
    return downloadFile(cell.fileUrl, booru.domain(), cell.filename(), () {});
  }

  Future<int> _goToPage(int i) {
    return booru.page(i, tags).then((value) {
      if (context.mounted) {
        setState(() {
          currentPage = i;
          posts = value;
        });
      }

      return Future.value(value.length);
    });
  }

  void _search(String value) {
    setState(() {
      posts = null;
      tags = value;
      booru.page(0, tags).then((value) {
        setState(() {
          posts = value;
        });
      });
      Navigator.popUntil(context, ModalRoute.withName("/booru"));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(tags == "" ? currentPage.toString() : tags),
          actions: [
            IconButton(
                onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SearchBooru(onSubmitted: _search);
                    })),
                icon: const Icon(Icons.search)),
          ],
        ),
        drawer: makeDrawer(context, false),
        body: WillPopScope(
          onWillPop: () {
            return Future.value(true);
          },
          child: posts == null
              ? const LinearProgressIndicator()
              : () {
                  var cells = postsToCells(posts!, _search);

                  return ImageGrid<BooruCell>(
                    refresh: () => _goToPage(currentPage),
                    hideAlias: true,
                    numbRow: 2,
                    getCell: (i) => cells[i],
                    onLongPress: _download,
                  );
                }(),
        ));
  }
}

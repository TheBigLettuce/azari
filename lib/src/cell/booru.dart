import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/cell/data.dart';

import 'cell.dart';

class BooruCell extends Cell {
  String originalUrl;

  @override
  Future<CellData> getFile() async {
    return CellData(thumb: CachedNetworkImageProvider(path), name: alias);
  }

  @override
  String url() => originalUrl;

  BooruCell(
      {required super.alias,
      required super.path,
      required this.originalUrl,
      required String tags,
      required void Function(String tag) onTagPressed})
      : super(addInfo: () {
          var list = [
            const ListTile(
              title: Text("Tags"),
            )
          ];
          list.addAll(tags.split(' ').map((e) => ListTile(
                title: Text(e),
                onTap: () {
                  Tags().addLatest(e);
                  onTagPressed(e);
                },
              )));

          return [
            ListBody(
              children: list,
            )
          ];
        });
}

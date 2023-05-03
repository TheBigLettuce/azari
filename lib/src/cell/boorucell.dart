import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/cell/image.dart';

class BooruCell extends ImageCell {
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
      required tags})
      : super(addInfo: [
          ListTile(
            title: const Text("Tags"),
            subtitle: Text(tags),
          )
        ]);
}

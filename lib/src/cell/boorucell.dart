import 'dart:typed_data';

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
      : super(hash: Uint8List(0), orighash: Uint8List(0), type: 1, addInfo: [
          ListTile(
            title: const Text("Tags"),
            subtitle: Text(tags),
          )
        ]);
}

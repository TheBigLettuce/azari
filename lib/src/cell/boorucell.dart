import 'dart:ffi';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/cell/image.dart';
import 'package:http/http.dart' as http;

class BooruCell extends ImageCell {
  String originalUrl;

  @override
  Future<CellData> getFile() async {
    return CellData(thumb: NetworkImage(originalUrl), name: alias)
    var req = http.get(Uri.parse(path));

    return Future(() async {
      try {
        var r = await req;

        if (r.statusCode != 200) {
          throw "not 200";
        }

        return CellData(thumb: , name: alias);
      } catch (e) {
        return Future.error(e);
      }
    });
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

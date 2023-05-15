import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:mime/mime.dart';

import 'cell.dart';
import 'data.dart';

class BooruCell extends Cell {
  String originalUrl;
  String sampleUrl;

  @override
  String fileDownloadUrl() => originalUrl;

  @override
  Content fileDisplay() {
    var settings = isar().settings.getSync(0);
    String url;
    if (settings!.quality == DisplayQuality.original) {
      url = originalUrl;
    } else if (settings.quality == DisplayQuality.sample) {
      url = sampleUrl;
    } else {
      throw "invalid display quality";
    }

    var type = lookupMimeType(url);
    if (type == null) {
      return Content("", false);
    }

    var typeHalf = type.split("/")[0];

    if (typeHalf == "image") {
      return Content(typeHalf, false, image: NetworkImage(url));
    } else if (typeHalf == "video") {
      return Content(typeHalf, false, videoPath: url);
    } else {
      return Content(typeHalf, false);
    }
  }

  @override
  CellData getCellData() => CellData(
      thumb: () {
        return CachedNetworkImageProvider(path);
      },
      name: alias);

  BooruCell(
      {required super.alias,
      required super.path,
      required this.originalUrl,
      required String tags,
      required this.sampleUrl,
      required void Function(String tag) onTagPressed})
      : super(addInfo: (dynamic extra) {
          var list = [
            const ListTile(
              title: Text("Tags"),
            )
          ];
          list.addAll(tags.split(' ').map((e) => ListTile(
                title: Text(HtmlUnescape().convert(e)),
                onTap: () {
                  onTagPressed(HtmlUnescape().convert(e));
                  extra();
                },
              )));

          return [
            ListBody(
              children: list,
            )
          ];
        }, addButtons: () {
          if (tags.contains("original")) {
            return [
              const IconButton(
                icon: Icon(IconData(79)),
                onPressed: null,
              )
            ];
          }

          return null;
        });
}

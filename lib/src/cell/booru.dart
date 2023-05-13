import 'package:flutter/material.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:html_unescape/html_unescape_small.dart';

import 'cell.dart';

class BooruCell extends Cell {
  String originalUrl;
  String sampleUrl;

  @override
  String fileDownloadUrl() => originalUrl;

  @override
  String fileDisplayUrl() {
    var settings = isar().settings.getSync(0);
    if (settings!.quality == DisplayQuality.original) {
      return originalUrl;
    } else if (settings.quality == DisplayQuality.sample) {
      return sampleUrl;
    } else {
      throw "invalid display quality";
    }
  }

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
                  onTagPressed(e);
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

import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart' as convert;
import 'package:flutter/widgets.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'cell.dart';

class ImageCell extends Cell {
  Uint8List orighash;
  int type;
  List<Widget>? addInfo;

  ImageCell.fromJson(Map<String, dynamic> m)
      : orighash = base64Decode(m["orighash"]),
        type = m["type"],
        super(
            alias: m["name"],
            hash: base64Decode(m["thumbhash"]),
            path: m["dir"]);

  Map<String, dynamic> toJson() => {
        "dir": super.path,
        "alias": super.alias,
        "thumbhash": base64Encode(super.hash),
        "orighash": base64Encode(orighash),
        "type": type,
      };

  String url() {
    var settings = isar().settings.getSync(0);
    if (settings!.serverAddress == "") {
      return "";
    }

    return "${settings.serverAddress}/static/${convert.hex.encode(orighash)}";
  }

  ImageCell(
      {required super.alias,
      required super.hash,
      required super.path,
      required this.orighash,
      required this.type,
      this.addInfo});
}

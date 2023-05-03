import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart' as convert;
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'cell.dart';
import 'package:http/http.dart' as http;

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
    return Hive.box("settings").get("serverAddress") +
        "/static/${convert.hex.encode(orighash)}";
  }

  ImageCell(
      {required super.alias,
      required super.hash,
      required super.path,
      required this.orighash,
      required this.type,
      this.addInfo});
}

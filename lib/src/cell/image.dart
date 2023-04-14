import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart' as convert;
import 'cell.dart';

class ImageCell extends Cell {
  Uint8List orighash;
  int type;

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
    return "http://localhost:8080/static/${convert.hex.encode(orighash)}";
  }

  ImageCell(
      {required super.alias,
      required super.hash,
      required super.path,
      required this.orighash,
      required this.type});
}

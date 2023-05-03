import 'dart:convert';
import 'package:http/http.dart' as http;

import 'cell.dart';

class DirectoryCell extends Cell {
  DirectoryCell.fromJson(
    Map<String, dynamic> m,
  ) : super(
            alias: m["alias"],
            hash: base64Decode(m["thumbhash"]),
            path: m["path"]);

  Map<String, dynamic> toJson() => {
        "path": super.path,
        "alias": alias,
        "thumbhash": base64Encode(super.hash)
      };

  @override
  Future delete() async {}

  DirectoryCell({
    required super.hash,
    required super.path,
    required super.alias,
  });
}

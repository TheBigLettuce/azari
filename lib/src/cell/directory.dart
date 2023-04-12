import 'dart:convert';
import 'package:path/path.dart' as path;

import 'package:flutter/material.dart';

import 'cell.dart';

class DirectoryCell extends Cell {
  DirectoryCell.fromJson(
    Map<String, dynamic> m,
  ) : super(
            alias: path.basename(m["path"]),
            hash: base64Decode(m["thumbhash"]),
            path: m["path"]);

  Map<String, dynamic> toJson() => {
        "path": super.path,
        "alias": alias,
        "thumbhash": base64Encode(super.hash)
      };

  DirectoryCell({
    required super.hash,
    required super.path,
    required super.alias,
  });
}

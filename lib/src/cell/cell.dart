import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:convert/convert.dart' as convert;
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/settings.dart';

import 'data.dart';

class Cell {
  String path;
  String alias;
  Uint8List hash;

  Future<CellData> getFile() async {
    return CellData(
        thumb: NetworkImage(
            "${isar().settings.getSync(0)!.serverAddress}/static/${convert.hex.encode(hash)}"),
        name: alias);
  }

  Cell({required this.path, required this.hash, required this.alias});
}

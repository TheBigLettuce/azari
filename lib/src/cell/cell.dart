import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:convert/convert.dart' as convert;
import 'package:flutter/material.dart';

import 'data.dart';

class Cell {
  String path;
  String alias;
  Uint8List hash;

  Future<CellData> getFile() async {
    http.Response resp;
    try {
      resp = await http.get(Uri.parse(
          "http://localhost:8080/static/${convert.hex.encode(hash)}"));
    } catch (e) {
      return Future.error(e);
    }

    return Future((() {
      if (resp.statusCode != 200) {
        return Future.error("status code is not ok");
      }

      return CellData(thumb: resp.bodyBytes, name: alias);
    }));
  }

  Cell({required this.path, required this.hash, required this.alias});
}

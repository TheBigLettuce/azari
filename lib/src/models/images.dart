import 'dart:convert';
import 'core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../cell/image.dart';
import 'grid_list.dart';

class ImagesModel extends CoreModel with GridList<ImageCell> {
  String dir;

  @override
  Future<List<ImageCell>> fetchRes() async {
    http.Response resp;
    try {
      resp = await http.get(
          Uri.http("localhost:8080", "/files", {"dir": dir, "types": "image"}));
    } catch (e) {
      return Future.error(e);
    }

    return Future((() {
      var r = resp;
      if (r.statusCode != 200) {
        return Future.error("status code is not ok");
      }

      List<ImageCell> list = [];
      List<dynamic> j = json.decode(r.body);
      for (var element in j) {
        list.add(ImageCell.fromJson(element));
      }

      return list; //Future.error("invalid type for directories");
    }));
  }

  @override
  Future refresh() => super.refreshFuture(fetchRes());

  ImagesModel({required this.dir});
}

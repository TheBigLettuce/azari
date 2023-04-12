import 'dart:convert';

import 'package:flutter/material.dart';
import 'core.dart';

import '../cell/directory.dart';
import 'package:http/http.dart' as http;

import 'grid_list.dart';

class DirectoryModel extends CoreModel with GridList<DirectoryCell> {
  //final Function(String dir, BuildContext context) onPressedFunc;

  @override
  Future<List<DirectoryCell>> fetchRes() async {
    http.Response resp;
    try {
      resp = await http.get(Uri.parse("http://localhost:8080/dirs"));
    } catch (e) {
      return Future.error(e);
    }

    return Future((() {
      var r = resp;
      if (r.statusCode != 200) {
        return Future.error("status code is not ok");
      }

      List<DirectoryCell> list = [];
      List<dynamic> j = json.decode(r.body);
      for (var element in j) {
        list.add(DirectoryCell.fromJson(element));
      }

      return list; //Future.error("invalid type for directories");
    }));
  }

  //@override
  //void onPressed(String dir, BuildContext context) => onPressedFunc;

  @override
  Future refresh() => super.refreshFuture(fetchRes());

  DirectoryModel();
}


/* */
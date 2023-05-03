import 'dart:convert';
import 'package:hive/hive.dart';

import 'core.dart';
import 'package:http/http.dart' as http;

import '../cell/image.dart';
import 'grid_list.dart';

class ImagesModel extends CoreModel with GridList<ImageCell> {
  String dir;

  void Function(List<ImageCell>)? onRefresh;

  @override
  Future<List<ImageCell>> fetchRes() async {
    http.Response resp;
    try {
      resp = await http.get(
          Uri.parse(Hive.box("settings").get("serverAddress") +
              "/files?dir=$dir&types=${'image'}"),
          headers: {"deviceId": Hive.box("settings").get("deviceId")});
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
  Future delete(int indx) async {
    var e = get(indx);

    var req = http.MultipartRequest(
      "POST",
      Uri.parse(Hive.box("settings").get("serverAddress") + "/delete/file"),
    )
      ..fields["dir"] = e.path
      ..fields["file"] = e.alias
      ..headers["deviceId"] = Hive.box("settings").get("deviceId");

    return Future(() async {
      try {
        var resp = await req.send();

        if (resp.statusCode != 200) {
          return Future.error("status not ok");
        }

        refresh();
      } catch (e) {
        print(e.toString());
      }
    });
  }

  @override
  Future refresh() => super.refreshFuture(fetchRes(), onRefresh: onRefresh);

  void setOnRefresh(void Function(List<ImageCell> newList) onChange) =>
      onRefresh = onChange;

  ImagesModel({required this.dir});
}

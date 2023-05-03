import 'dart:convert';

import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/settings.dart';

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
      var settings = isar().settings.getSync(0);
      if (settings!.serverAddress == "") {
        throw "server address is unset";
      } else if (settings.deviceId == "") {
        throw "device id is unset";
      }
      resp = await http.get(
          Uri.parse(
              "${settings.serverAddress}/files?dir=$dir&types=${'image'}"),
          headers: {"deviceId": settings.deviceId});
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
    var settings = isar().settings.getSync(0);
    if (settings!.serverAddress == "") {
      return Future.error("server address is unset");
    } else if (settings.deviceId == "") {
      return Future.error("device id is unset");
    }

    var e = get(indx);

    var req = http.MultipartRequest(
      "POST",
      Uri.parse("${settings.serverAddress}/delete/file"),
    )
      ..fields["dir"] = e.path
      ..fields["file"] = e.alias
      ..headers["deviceId"] = settings.deviceId;

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

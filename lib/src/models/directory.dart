import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:hive/hive.dart';
import 'core.dart';

import '../cell/directory.dart';
import 'package:http/http.dart' as http;

import 'grid_list.dart';

class DirectoryModel extends CoreModel with GridList<DirectoryCell> {
  //final Function(String dir, BuildContext context) onPressedFunc;
  String? _directorySetError;
  String? _serverAddrSetError;
  String? _deviceIdSetError;

  String? get directorySetError => _directorySetError;
  set directorySetError(String? v) {
    _directorySetError = v;
    notifyListeners();
  }

  String? get serverAddrSetError => _serverAddrSetError;
  set serverAddrSetError(String? v) {
    _serverAddrSetError = v;
    notifyListeners();
  }

  String? get deviceIdSetError => _deviceIdSetError;
  set deviceIdSetError(String? v) {
    _deviceIdSetError = v;
    notifyListeners();
  }

  @override
  Future<List<DirectoryCell>> fetchRes() async {
    http.Response resp;
    try {
      resp = await http.get(
          Uri.parse(Hive.box("settings").get("serverAddress") + "/dirs"),
          headers: {"deviceId": Hive.box("settings").get("deviceId")});
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

  Future setDeviceId(String value) async {
    if (value.isEmpty) {
      deviceIdSetError = "Value is empty";
      return;
    }

    var req = http.MultipartRequest(
        'POST',
        Uri.parse(
            Hive.box("settings").get("serverAddress") + "/device/register"))
      ..fields["key"] = value
      ..headers["deviceId"] = Hive.box("settings").get("deviceId");

    return req.send().then((v) async {
      if (v.statusCode != 200) {
        throw "status code not 200";
      }

      var id = await v.stream.toBytes();

      if (id.isEmpty) {
        throw "got empty bytes";
      }

      await Hive.box("settings").put("deviceId", hex.encode(id));
    }).onError(
      (error, stackTrace) {
        deviceIdSetError = error.toString();
      },
    ).whenComplete(() {
      notifyListeners();
    });
  }

  void setDirectory(String value) async {
    if (value.isEmpty) {
      serverAddrSetError = "Value is empty";
      return;
    }

    await Hive.box("settings").put("directory", value);
    notifyListeners();
  }

  void setServerAddress(String value) async {
    if (value.isEmpty) {
      serverAddrSetError = "Value is empty";
      return;
    }

    try {
      var resp = await http.get(Uri.parse("$value/hello"));
      if (resp.statusCode != 200) {
        serverAddrSetError = "Server returns not OK";
        return;
      }
    } catch (e) {
      serverAddrSetError = e.toString();
      return;
    }

    await Hive.box("settings").put("serverAddress", value);
    notifyListeners();
  }

  @override
  Future refresh() => super.refreshFuture(fetchRes());

  bool isDirectorySet() => Hive.box("settings").containsKey("directory");
  bool isDeviceIdSet() {
    var value = Hive.box("settings").get("deviceId");

    return value != null && value != "";
  }

  bool isServerAddressSet() =>
      Hive.box("settings").containsKey("serverAddress");

  DirectoryModel();
}

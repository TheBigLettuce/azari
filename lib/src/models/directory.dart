import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/models/download_manager.dart';
import 'package:hive/hive.dart';
import 'core.dart';
import 'package:path/path.dart' as path;

import '../cell/directory.dart';
import 'package:http/http.dart' as http;

import 'grid_list.dart';

mixin ServerAddr on CoreModel {
  String? _serverAddrSetError;

  String? get serverAddrSetError => _serverAddrSetError;
  set serverAddrSetError(String? v) {
    _serverAddrSetError = v;
    notifyListeners();
  }

  bool isServerAddressSet() =>
      Hive.box("settings").containsKey("serverAddress");

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
}

mixin DeviceId on CoreModel {
  String? _deviceIdSetError;

  String? get deviceIdSetError => _deviceIdSetError;
  set deviceIdSetError(String? v) {
    _deviceIdSetError = v;
    notifyListeners();
  }

  bool isDeviceIdSet() {
    var value = Hive.box("settings").get("deviceId");

    return value != null && value != "";
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
      ..headers["deviceId"] = value;

    return req.send().then((v) async {
      if (v.statusCode != 200) {
        return Future.error("status code not 200");
      }

      var id = await v.stream.toBytes();

      if (id.isEmpty) {
        return Future.error("got empty bytes");
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
}

class DirectoryModel extends CoreModel
    with GridList<DirectoryCell>, DeviceId, ServerAddr, DownloadManager {
  //final Function(String dir, BuildContext context) onPressedFunc;
  String? _directorySetError;

  String? get directorySetError => _directorySetError;
  set directorySetError(String? v) {
    _directorySetError = v;
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

  void setDirectory(String value) async {
    if (value.isEmpty) {
      directorySetError = "Value is empty";
      return;
    }

    await Hive.box("settings").put("directory", value);
    notifyListeners();
  }

  @override
  Future delete(int indx) async {}

  @override
  Future refresh() => super.refreshFuture(fetchRes());

  bool isDirectorySet() => Hive.box("settings").containsKey("directory");

  void chooseFilesAndUpload(Function(Object? err) onError,
      {String? childDir, Function()? childOnSuccess, String? forcedDir}) async {
    var dir = Hive.box("settings").get("directory");

    FilePickerResult? result = await FilePicker.platform.pickFiles(
        lockParentWindow: true,
        allowMultiple: true,
        allowCompression: false,
        dialogTitle: "Pick files to upload",
        type: FileType.image,
        withReadStream: false,
        initialDirectory:
            childDir == null ? dir : path.joinAll([dir, childDir]));

    if (result == null) {
      onError("result is nil");
      return;
    } else {
      const ch = MethodChannel("org.gallery");

      var map = <String, dynamic>{
        "type": 1,
        "files": result.files.map((e) => e.path!).toList(),
        "deviceId": Hive.box("settings").get("deviceId"),
        "baseDirectory": dir,
        "serverAddress": Hive.box("settings").get("serverAddress"),
      };

      if (forcedDir != null) {
        map["forcedDir"] = forcedDir;
      }

      try {
        var res = ch.invokeMethod("addFiles", json.encode(map));

        res.then((value) => print("succes")).onError((error, stackTrace) {
          onError(error);
        }).whenComplete(() {
          if (childDir != null && childOnSuccess != null) {
            childOnSuccess();
          }
          refresh();
        });
      } on PlatformException catch (e) {
        onError(e);
      } catch (e) {
        onError(e);
      }
    }
  }

  bool _isInitalized = false;

  Future initalize(BuildContext context) async {
    if (!_isInitalized) {
      _isInitalized = true;

      await refresh();

      // ignore: use_build_context_synchronously
      initDownloadManager(context);

      return Future.value(true);
    }

    return Future.value(true);
  }

  DirectoryModel();
}

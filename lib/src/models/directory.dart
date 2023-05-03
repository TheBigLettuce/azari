import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/models/download_manager.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:isar/isar.dart';
import '../db/isar.dart';
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

  bool isServerAddressSet() {
    var settings = isar().settings.getSync(0);
    if (settings == null || settings.serverAddress == "") {
      return false;
    }

    return true;
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

    _setSettings(serverAddress: value);

    notifyListeners();
  }
}

void _setSettings(
    {String? serverAddress, String? deviceId, String? path}) async {
  var settings = isar().settings.getSync(0);

  settings ??= Settings.empty();

  isar().writeTxnSync(() {
    isar().settings.putSync(Settings(
        serverAddress: serverAddress ?? settings!.serverAddress,
        deviceId: deviceId ?? settings!.deviceId,
        path: path ?? settings!.path));
  });
}

mixin DeviceId on CoreModel {
  String? _deviceIdSetError;

  String? get deviceIdSetError => _deviceIdSetError;
  set deviceIdSetError(String? v) {
    _deviceIdSetError = v;
    notifyListeners();
  }

  bool isDeviceIdSet() {
    var settings = isar().settings.getSync(0);
    if (settings == null || settings.deviceId == "") {
      return false;
    }

    return true;
  }

  Future setDeviceId(String value) async {
    if (value.isEmpty) {
      deviceIdSetError = "Value is empty";
      return;
    }

    var settings = isar().settings.getSync(0);
    if (settings == null || settings.serverAddress == "") {
      deviceIdSetError = "server address is unset";
      return;
    }

    var req = http.MultipartRequest(
        'POST', Uri.parse("${settings.serverAddress}/device/register"))
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

      _setSettings(deviceId: hex.encode(id));
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
      var settings = isar().settings.getSync(0);
      if (settings!.serverAddress == "") {
        throw "server address is unset";
      } else if (settings.deviceId == "") {
        throw "device id is unset";
      }

      resp = await http.get(Uri.parse("${settings.serverAddress}/dirs"),
          headers: {"deviceId": settings.deviceId});
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

    _setSettings(path: value);
    notifyListeners();
  }

  @override
  Future delete(int indx) async {}

  @override
  Future refresh() => super.refreshFuture(fetchRes());

  bool isDirectorySet() {
    var settings = isar().settings.getSync(0);
    if (settings == null || settings.path == "") {
      return false;
    }

    return true;
  }

  void chooseFilesAndUpload(Function(Object? err) onError,
      {String? childDir, Function()? childOnSuccess, String? forcedDir}) async {
    var settings = isar().settings.getSync(0);
    if (settings!.path == "") {
      onError("path is unset");
      return;
    } else if (settings.deviceId == "") {
      onError("device id is unset");
      return;
    } else if (settings.serverAddress == "") {
      onError("server address is unset");
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
        lockParentWindow: true,
        allowMultiple: true,
        allowCompression: false,
        dialogTitle: "Pick files to upload",
        type: FileType.image,
        withReadStream: false,
        initialDirectory: childDir == null
            ? settings.path
            : path.joinAll([settings.path, childDir]));

    if (result == null) {
      onError("result is nil");
      return;
    } else {
      const ch = MethodChannel("org.gallery");

      var map = <String, dynamic>{
        "type": 1,
        "files": result.files.map((e) => e.path!).toList(),
        "deviceId": settings.deviceId,
        "baseDirectory": settings.path,
        "serverAddress": settings.serverAddress,
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

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import 'package:gallery/src/schemas/settings.dart';
import 'package:permission_handler/permission_handler.dart';
import '../cell/directory.dart';
import '../db/isar.dart';
import 'core.dart';

import 'grid_list.dart';

class DirectoryModel extends CoreModel {
  //final Function(String dir, BuildContext context) onPressedFunc;
  String? _directorySetError;

  String? get directorySetError => _directorySetError;
  set directorySetError(String? v) {
    _directorySetError = v;
    notifyListeners();
  }

  @override
  Future<List<DirectoryCell>> fetchRes() async {
    return Future.error("unimplimented");
  }

  void setDirectory(String value) async {
    if (value.isEmpty) {
      directorySetError = "Value is empty";
      return;
    }

    var oldSettings = isar().settings.getSync(0) ?? Settings.empty();

    isar().writeTxnSync(
      () {
        isar().settings.putSync(oldSettings.copy(path: value));
      },
    );
    notifyListeners();
  }

  @override
  Future delete(int indx) async {}

  @override
  Future refresh() => Future.value(true);

  bool isDirectorySet() {
    var settings = isar().settings.getSync(0);
    if (settings == null || settings.path == "") {
      return false;
    }

    return true;
  }

  void pickDirectory() async {
    var pickedDir = await FilePicker.platform.getDirectoryPath();
    if (pickedDir == null ||
        pickedDir == "" ||
        FileStat.statSync(pickedDir).type == FileSystemEntityType.notFound) {
      directorySetError = "Path is invalid";
      return;
    }

    await Permission.manageExternalStorage.request();

    setDirectory(pickedDir);
  }

  bool _isInitalized = false;

  Future initalize(Color navBarColor) async {
    if (!_isInitalized) {
      _isInitalized = true;

      var settings = isar().settings.getSync(0)!;

      if (settings.enableGallery) {
        await refresh();
      }

      if (settings.picturesPerRow <= 0) {
        isar().writeTxnSync(
            () => isar().settings.putSync(settings.copy(picturesPerRow: 2)));
      }

      await Permission.notification.request();

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            systemNavigationBarColor: navBarColor.withOpacity(0)),
      );

      return Future.value(true);
    }

    return Future.value(true);
  }
}

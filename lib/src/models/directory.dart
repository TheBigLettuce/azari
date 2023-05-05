import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:gallery/src/schemas/settings.dart';
import 'package:permission_handler/permission_handler.dart';
import '../cell/directory.dart';
import '../db/isar.dart';
import 'core.dart';

import 'grid_list.dart';

class DirectoryModel extends CoreModel with GridList<DirectoryCell> {
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
  Future refresh() => super.refreshFuture(fetchRes());

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

    setDirectory(pickedDir);
  }

  bool _isInitalized = false;

  Future initalize() async {
    if (!_isInitalized) {
      _isInitalized = true;

      await refresh();

      // ignore: use_build_context_synchronously
      await Permission.manageExternalStorage.request();

      return Future.value(true);
    }

    return Future.value(true);
  }
}

import 'package:flutter/material.dart';
import 'package:gallery/src/models/download_manager.dart';
import 'package:gallery/src/schemas/settings.dart';
import '../cell/directory.dart';
import '../db/isar.dart';
import 'core.dart';

import 'grid_list.dart';

class DirectoryModel extends CoreModel
    with GridList<DirectoryCell>, DownloadManager {
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

    isar().writeTxnSync(
      () {
        isar().settings.putSync(Settings(path: value));
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
}

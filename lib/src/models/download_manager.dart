import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/models/core.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

mixin DownloadManager on CoreModel {
  Future download(String url, String dir, String name) async {
    return Dio().download(
      url,
      path.joinAll([isar().settings.getSync(0)!.path, dir, name]),
    );
  }

  void initDownloadManager(BuildContext context) async {
    await Permission.manageExternalStorage.request();
  }
}

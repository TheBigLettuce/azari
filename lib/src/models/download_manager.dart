import 'dart:isolate';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/models/core.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

mixin DownloadManager on CoreModel {
  Future download(String url, String dir, String name) async {
    return Dio().download(
      url,
      path.joinAll([Hive.box("settings").get("directory"), dir, name]),
    );
  }

  void initDownloadManager(BuildContext context) async {
    await Permission.manageExternalStorage.request();
  }
}

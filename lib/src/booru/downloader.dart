import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/schemas/download_file.dart' as dw_file;
import 'package:gallery/src/schemas/settings.dart';
import 'package:isar/isar.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_storage/saf.dart';
import '../db/isar.dart';
import 'package:http/http.dart' as http;

Downloader? _global;

class Download {
  String url;
  String dir;
  String name;
  int? id;

  Download(this.url, this.dir, this.name, {this.id});
}

class Downloader {
  int _inWork = 0;
  final Dio dio = Dio();
  final int maximum;
  //final List<Download> _downloads = [];
  final Map<int, CancelToken> _tokens = {};

  void _addToken(int key, CancelToken t) => _tokens[key] = t;
  void _removeToken(int key) => _tokens.remove(key);
  bool _hasCancelKey(int id) => _tokens[id] != null;

  void retry(dw_file.File f) {
    if (f.isOnHold()) {
      isar().writeTxnSync(() => isar().files.putSync(f.failed()));
    } else if (_hasCancelKey(f.id!)) {
      cancelAndRemoveToken(f.id!);
    } else {
      add(f);
    }
  }

  String downloadAction(dw_file.File f) {
    if (f.isOnHold() || _hasCancelKey(f.id!)) {
      return "Cancel the download?";
    } else {
      return "Retry?";
    }
  }

  String downloadDescription(dw_file.File f) {
    if (f.isOnHold()) {
      return "On hold";
    }

    if (_hasCancelKey(f.id!)) {
      return "In progress";
    }

    return "Failed";
  }

  void cancelAndRemoveToken(int key) {
    var t = _tokens[key];
    if (t == null) {
      return;
    }

    t.cancel();
    _tokens.remove(key);
  }

  void _done() {
    if (_inWork <= maximum) {
      var f = isar()
          .files
          .filter()
          .inProgressEqualTo(false)
          .isFailedEqualTo(false)
          .findFirstSync();
      if (f != null) {
        isar().writeTxnSync(
          () => isar().files.putSync(f.inprogress()),
        );
        _addToken(f.id!, CancelToken());
        _download(f);
      } else {
        _inWork--;
      }
    } else {
      _inWork--;
    }
  }

  void add(dw_file.File download) async {
    //var settings = isar().settings.getSync(0)!;
    /*var canw = await canWrite(Uri.parse(settings.path));
    if (canw ?? false) {
      print("cant write");
      return;
    }*/

    if (download.id != null && _hasCancelKey(download.id!)) {
      return;
    }

    isar().writeTxnSync(() => isar().files.putSync(download.onHold()));

    if (_inWork <= maximum) {
      _inWork++;
      var d = download.inprogress();
      var id = isar().writeTxnSync(() => isar().files.putSync(d));
      _download(d);
      _addToken(id, CancelToken());
    }
  }

  void _download(dw_file.File d) async {
    var tempd = await getTemporaryDirectory();
    var dirpath = path.joinAll([tempd.path, d.site]);
    try {
      await Directory(dirpath).create();
    } catch (e) {
      print("while creating directory $dirpath: $e");
      return;
    }

    var filePath = path.joinAll([tempd.path, d.site, d.name]);

    // can it throw 🤔
    if (File(filePath).existsSync()) {
      _done();
    }

    Dio().download(d.url, filePath,
        cancelToken: _tokens[d.id],
        deleteOnError: true, onReceiveProgress: ((count, total) {
      if (count == total || !_hasCancelKey(d.id!)) {
        FlutterLocalNotificationsPlugin().cancel(d.id!);
        return;
      }

      FlutterLocalNotificationsPlugin().show(
        d.id!,
        d.site,
        d.name,
        NotificationDetails(
          android: AndroidNotificationDetails("download", "Dowloader",
              groupKey: d.site,
              ongoing: true,
              playSound: false,
              enableLights: false,
              enableVibration: false,
              category: AndroidNotificationCategory.progress,
              maxProgress: total,
              progress: count,
              visibility: NotificationVisibility.private,
              indeterminate: total == -1,
              showProgress: true),
        ),
      );
    })).then((value) {
      isar().writeTxnSync(
        () {
          _removeToken(d.id!);
          isar().files.deleteSync(d.id!);
        },
      );
    }).onError((error, stackTrace) {
      isar().writeTxnSync(
        () {
          _removeToken(d.id!);
          isar().files.putSync(d.failed());
        },
      );
      FlutterLocalNotificationsPlugin().cancel(d.id!);
    }).whenComplete(() async {
      try {
        var fileFrom = File(filePath).openRead();

        var settings = isar().settings.getSync(0)!;
        var f = await Uri.parse(settings.path).toDocumentFile();
        if (f == null) {
          return;
        }

        var child = await f.child(d.site, requiresWriteAccess: true);
        child ??= await f.createDirectory(d.site);

        if (child == null) {
          return;
        }

        var fileTo = await child.createFile(
          displayName: d.name,
          mimeType: lookupMimeType(d.name)!,
        );
        if (fileTo == null) {
          return;
        }

        var subsc = fileFrom.listen(null);
        subsc.onData((event) async {
          bool? result;
          try {
            result = await fileTo.writeToFileAsBytes(
                bytes: Uint8List.fromList(event), mode: FileMode.append);
          } catch (_) {
            subsc.cancel();
          }

          if (result == null || !result) {
            subsc.cancel();
          }
        });
        subsc.onDone(() {
          try {
            File(filePath).deleteSync();
          } catch (_) {}
          _done();
        });
      } catch (e) {
        print("while writting the downloaded file to uri: $e");

        try {
          File(filePath).deleteSync();
        } catch (_) {}

        isar().writeTxnSync(
          () {
            _removeToken(d.id!);
            isar().files.putSync(d.failed());
          },
        );
      }
    });
  }

  Downloader._new(this.maximum);

  factory Downloader() {
    if (_global != null) {
      return _global!;
    } else {
      _global = Downloader._new(6);
      return _global!;
    }
  }
}

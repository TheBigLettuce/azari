import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../db/isar.dart';

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
  final int maximum;
  //final List<Download> _downloads = [];
  final Map<int, CancelToken> _tokens = {};

  void _addToken(int key, CancelToken t) => _tokens[key] = t;
  void _removeToken(int key) => _tokens.remove(key);
  bool _hasCancelKey(int id) => _tokens[id] != null;

  void retry(File f) {
    if (f.isOnHold()) {
      isar().writeTxnSync(() => isar().files.putSync(f.failed()));
    } else if (_hasCancelKey(f.id!)) {
      cancelAndRemoveToken(f.id!);
    } else {
      add(f);
    }
  }

  String downloadAction(File f) {
    if (f.isOnHold() || _hasCancelKey(f.id!)) {
      return "Cancel the download?";
    } else {
      return "Retry?";
    }
  }

  String downloadDescription(File f) {
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

  void add(File download) {
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

  void _download(File d) async {
    if (!await Permission.manageExternalStorage.isGranted) {
      return;
    }

    var filePath =
        path.joinAll([isar().settings.getSync(0)!.path, d.site, d.name]);

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
              importance: Importance.low,
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
    }).whenComplete(_done);
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

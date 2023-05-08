import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import '../db/isar.dart';

Future downloadFile(String url, String dir, String name, {int? oldid}) async {
  if (!await Permission.manageExternalStorage.isGranted) {
    return;
  }

  if (isar()
          .files
          .filter()
          .nameEqualTo(name)
          .siteEqualTo(dir)
          .inProgressEqualTo(false)
          .findFirstSync() !=
      null) {
    if (oldid != null && hasCancelKey(oldid)) {
      return;
    }
  }

  var id = isar().writeTxnSync(() {
    return isar().files.putSync(File(url, true, dir, name, id: oldid));
  });

  var token = CancelToken();
  addToken(id, token);

  var filePath = path.joinAll([isar().settings.getSync(0)!.path, dir, name]);

  return Dio().download(url, filePath, cancelToken: token, deleteOnError: true,
      onReceiveProgress: ((count, total) {
    if (count == total || !hasCancelKey(id)) {
      FlutterLocalNotificationsPlugin().cancel(id);
      return;
    }

    FlutterLocalNotificationsPlugin().show(
      id,
      dir,
      name,
      NotificationDetails(
        android: AndroidNotificationDetails("download", "Dowloader",
            groupKey: dir,
            ongoing: true,
            playSound: false,
            enableLights: false,
            enableVibration: false,
            category: AndroidNotificationCategory.progress,
            maxProgress: total,
            progress: count,
            indeterminate: total == -1,
            showProgress: true),
      ),
    );
  })).then((value) {
    isar().writeTxnSync(
      () {
        removeToken(id);
        isar().files.deleteSync(id);
      },
    );
    ImageGallerySaver.saveFile(filePath);
  }).onError((error, stackTrace) {
    print(error);
    isar().writeTxnSync(
      () {
        removeToken(id);
        var file = File(url, false, dir, name);
        file.id = id;
        isar().files.putSync(file);
      },
    );
    FlutterLocalNotificationsPlugin().cancel(id);
  });
}

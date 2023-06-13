import 'dart:convert';
import 'dart:developer';

import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/gallery/uploader/uploader.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/server_settings.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart';

Map<String, dynamic> _deviceId(ServerSettings s) => {
      "deviceId": hex.encode(s.deviceId),
    };

ServerSettings _settings() {
  var settings = isar().serverSettings.getSync(0);

  if (settings == null) {
    throw "Server settings should be set";
  }

  return settings;
}

String _fromBaseToHex(String v) {
  return hex.encode(base64Decode(v));
}

class ServerAPI implements GalleryAPI<DirectoryFileShrinked> {
  Isar serverIsar;

  @override
  Dio client = Dio(BaseOptions(
      responseType: ResponseType.json,
      contentType: Headers.formUrlEncodedContentType))
    ..interceptors.add(LogInterceptor(responseBody: false, requestBody: true));

  @override
  Future<Result<Directory>> directories() async {
    var settings = _settings();

    var resp = await client.getUri(
      Uri.parse(settings.host).replace(path: "/dirs"),
      options: Options(headers: _deviceId(settings)),
    );
    if (resp.statusCode != 200) {
      throw resp.data;
    }

    serverIsar.writeTxnSync(() {
      serverIsar.clearSync();

      var list = (resp.data as List)
          .map((e) => Directory("",
              time: e["time"],
              dirName: e["alias"],
              count: e["count"],
              imageUrl: Uri.parse(settings.host)
                  .replace(path: '/static/${_fromBaseToHex(e["thumbhash"])}')
                  .toString(),
              dirPath: e["path"]))
          .toList();
      list.sort((v1, v2) {
        if (v1.time < v2.time) {
          return 1;
        } else if (v1.time > v2.time) {
          return -1;
        } else {
          return 0;
        }
      });

      serverIsar.directorys.putAllSync(list);
    });

    return Result((i) => serverIsar.directorys.getSync(i + 1)!,
        serverIsar.directorys.countSync());
  }

  @override
  void close() {
    serverIsar.close();
    client.close(force: true);
  }

  ServerAPI(this.serverIsar);

  @override
  GalleryAPIFiles<DirectoryFileShrinked> images(Directory d) {
    return _ImagesImpl(openServerApiInnerIsar(), client, d);
  }

  @override
  Future newDirectory(String path, void Function() onDone) async {
    var res = await FilePicker.platform.pickFiles(
        type: FileType.image, allowCompression: false, withReadStream: true);
    if (res == null) {
      throw "no result";
    }

    var settings = _settings();

    Uploader().add(Uri.parse(settings.host),
        res.files.map((e) => FileAndDir(path, e)).toList(), onDone);

    return Future.value();
  }

  @override
  Future delete(Directory d) async {
    var settings = _settings();

    var resp = await client.postUri(
        Uri.parse(settings.host).replace(path: "/delete/dir/${d.dirPath}"),
        options: Options(headers: _deviceId(settings)));

    return Future.value();
  }

  Future _modifyDir(String dir, {String? newHash, String? newAlias}) async {
    var settings = _settings();

    var resp = await client
        .postUri(Uri.parse(settings.host).replace(path: "/modify/dir"),
            options: Options(
              headers: _deviceId(settings),
            ),
            data: {
          "dir": dir,
          if (newHash != null) "newhash": newHash,
          if (newAlias != null) "newalias": newAlias
        });

    return Future.value();
  }

  @override
  Future modify(Directory old, Directory newd) =>
      _modifyDir(old.dirPath, newAlias: newd.dirName);

  @override
  Future setThumbnail(String newThumb, Directory d) =>
      _modifyDir(d.dirPath, newHash: newThumb);
}

class _ImagesImpl implements GalleryAPIFiles<DirectoryFileShrinked> {
  Isar imageIsar;
  int page = 0;
  Dio client;
  Directory d;

  @override
  bool reachedEnd = false;

  Future<bool> nextImages() async {
    if (reachedEnd) {
      return true;
    }

    var settings = _settings();

    var resp = await client.postUri(
        Uri.parse(settings.host).replace(path: "/files"),
        options: Options(headers: _deviceId(settings)),
        data: {
          "dir": d.dirPath,
          // "types": "image",
          "page": page.toString(),
          "count": "20"
        });

    if (resp.statusCode != 200) {
      throw resp.data;
    }

    var list = (resp.data as List);

    if (list.isEmpty) {
      reachedEnd = true;
    } else {
      imageIsar.writeTxnSync(() {
        imageIsar.directoryFiles.putAllSync(list.map((e) {
          var tags = e["tags"];
          if (tags != null) {
            tags = (e["tags"] as List).cast<String>();
          } else {
            tags = <String>[];
          }

          return DirectoryFile(e["dir"],
              tags: tags,
              name: e["name"],
              time: e["time"],
              origHash: _fromBaseToHex(e["orighash"]),
              thumbHash: _fromBaseToHex(e["thumbhash"]),
              type: e["type"],
              host: settings.host);
        }).toList());
      });

      page++;
    }

    return false;
  }

  @override
  void close() {
    imageIsar.close(deleteFromDisk: true);
  }

  _ImagesImpl(this.imageIsar, this.client, this.d);

  @override
  Future<Result<DirectoryFile>> refresh() async {
    imageIsar.writeTxnSync(() => imageIsar.clearSync());
    reachedEnd = false;
    page = 0;

    for (;;) {
      if (await nextImages()) {
        break;
      }
    }

    var copy = openServerApiInnerIsar();

    imageIsar.writeTxnSync(() {
      var offset = 0;

      for (;;) {
        var sorted = imageIsar.directoryFiles
            .where()
            .sortByTimeDesc()
            .offset(offset)
            .limit(40)
            .findAllSync();
        offset += 40;

        for (var element in sorted) {
          element.isarId = null;
        }

        copy.writeTxnSync(() => copy.directoryFiles.putAllSync(sorted));

        if (sorted.length != 40) {
          break;
        }
      }
    });

    imageIsar.close(deleteFromDisk: true);

    imageIsar = copy;

    return Result((i) => imageIsar.directoryFiles.getSync(i + 1)!,
        imageIsar.directoryFiles.countSync());
  }

  @override
  Future uploadFiles(List<PlatformFile> l, void Function() onDone) {
    if (l.isEmpty) {
      throw "l is empty";
    }

    var settings = _settings();

    Uploader().add(Uri.parse(settings.host),
        l.map((e) => FileAndDir(d.dirPath, e)).toList(), onDone);

    return Future.value();
  }

  @override
  Future delete(DirectoryFile f) async {
    var settings = _settings();

    var resp = await client
        .postUri(Uri.parse(settings.host).replace(path: "/delete/file"),
            options: Options(
              headers: _deviceId(settings),
            ),
            data: {"dir": d.dirPath, "file": f.name});

    return Future.value();
  }

  @override
  Future deleteFiles(
      List<DirectoryFileShrinked> f, void Function() onDone) async {
    var settings = _settings();

    var resp = await client.postUri(
        Uri.parse(settings.host).replace(path: "/delete/files"),
        options: Options(
            headers: _deviceId(settings), contentType: Headers.jsonContentType),
        data: jsonEncode(f.map((e) => joinAll([e.dir, e.file])).toList()));
    if (resp.statusCode != 200) {
      throw resp.data;
    }

    onDone();
  }
}

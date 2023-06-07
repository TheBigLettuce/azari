import 'dart:convert';
import 'dart:developer';

import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform_file.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/interface.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/server_settings.dart';
import 'package:http_parser/http_parser.dart';
import 'package:isar/isar.dart';
import 'package:mime/mime.dart';

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

class ServerAPI implements GalleryAPI {
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
      serverIsar.directorys.putAllSync((resp.data as List)
          .map((e) => Directory("",
              dirName: e["alias"],
              imageUrl: Uri.parse(settings.host)
                  .replace(path: '/static/${_fromBaseToHex(e["thumbhash"])}')
                  .toString(),
              dirPath: e["path"]))
          .toList());
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
  GalleryAPIFiles images(Directory d) {
    return _ImagesImpl(openServerApiInnerIsar(), client, d);
  }

  @override
  Future newDirectory(String path) async {
    var res = await FilePicker.platform.pickFiles(
        type: FileType.image, allowCompression: false, withReadStream: true);
    if (res == null) {
      throw "no result";
    }

    var settings = _settings();

    return _addFile(Uri.parse(settings.host),
        [_FileAndDir(path, res.files.first)], settings, client);
  }

  @override
  Future delete(Directory d) async {
    var settings = _settings();

    var resp = await client.postUri(
        Uri.parse(settings.host).replace(path: "/delete/dir/${d.dirPath}"),
        options: Options(headers: _deviceId(settings)));

    return Future.value();
  }
}

Future _addFile(
    Uri host, List<_FileAndDir> f, ServerSettings settings, Dio client) async {
  var formData = FormData();

  for (var element in f) {
    var mimt = lookupMimeType(element.res.name);

    formData.files.add(MapEntry(
        element.res.name,
        MultipartFile(element.res.readStream!, element.res.size,
            filename: element.res.name,
            contentType: MediaType.parse(mimt!),
            headers: {
              "dir": [element.dir],
              "name": [element.res.name]
            })));
  }

  var req = await client.postUri(host.replace(path: "/add/files"),
      options: Options(
          headers: _deviceId(settings),
          contentType: Headers.multipartFormDataContentType),
      data: formData);

  if (req.statusCode != 200) {
    throw "not 200";
  }

  var failed = req.data["failed"];

  if (failed != null && (failed as List).isNotEmpty) {
    log('failed: ${req.data["failed"]}');
  }

  return Future.value();
}

class _FileAndDir {
  final String dir;
  final PlatformFile res;

  const _FileAndDir(this.dir, this.res);
}

class _ImagesImpl implements GalleryAPIFiles {
  Isar imageIsar;
  int page = 0;
  Dio client;
  Directory d;

  @override
  bool reachedEnd = false;

  @override
  Future<Result<DirectoryFile>> nextImages() async {
    if (reachedEnd) {
      return Result((i) => imageIsar.directoryFiles.getSync(i + 1)!,
          imageIsar.directoryFiles.countSync());
    }

    var settings = _settings();

    var resp = await client.postUri(
        Uri.parse(settings.host).replace(path: "/files"),
        options: Options(headers: _deviceId(settings)),
        data: {
          "dir": d.dirPath,
          "types": "image",
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
        imageIsar.directoryFiles.putAllSync(list
            .map((e) => DirectoryFile(e["dir"],
                name: e["name"],
                origHash: _fromBaseToHex(e["orighash"]),
                thumbHash: _fromBaseToHex(e["thumbhash"]),
                type: e["type"],
                host: settings.host))
            .toList());
      });

      page++;
    }

    return Result((i) => imageIsar.directoryFiles.getSync(i + 1)!,
        imageIsar.directoryFiles.countSync());
  }

  @override
  void close() {
    imageIsar.close(deleteFromDisk: true);
  }

  _ImagesImpl(this.imageIsar, this.client, this.d);

  @override
  Future<Result<DirectoryFile>> refresh() {
    imageIsar.writeTxnSync(() => imageIsar.clearSync());
    page = 0;

    return nextImages();
  }

  @override
  Future uploadFiles(List<PlatformFile> l) {
    var settings = _settings();

    return _addFile(Uri.parse(settings.host),
        l.map((e) => _FileAndDir(d.dirPath, e)).toList(), settings, client);
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
}

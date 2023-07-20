// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'server_api_directories.dart';

class _ImagesImpl
    implements GalleryAPIFilesReadWrite<ServerApiFilesExtra, DirectoryFile> {
  Isar imageIsar;

  int page = 0;
  Dio client;
  Directory d;

  late final filter = IsarFilter<DirectoryFile>(
      imageIsar, openServerApiInnerIsar(), (offset, limit, s) {
    return imageIsar.directoryFiles
        .filter()
        .nameContains(s)
        .offset(offset)
        .limit(limit)
        .findAllSync();
  });

  bool reachedEnd = false;

  @override
  ServerApiFilesExtra getExtra() {
    return ServerApiFilesExtra._(this);
  }

  @override
  DirectoryFile directCell(int i) {
    return imageIsar.directoryFiles.getSync(i + 1)!;
  }

  Future<bool> _nextImages() async {
    if (reachedEnd) {
      return true;
    }

    var resp = await client.postUri(
        Uri.parse(d.serverUrl).replace(path: "/files"),
        options: Options(headers: _deviceId()),
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
              host: d.serverUrl);
        }).toList());
      });

      page++;
    }

    return false;
  }

  void _writeFromTo(Isar from,
      List<DirectoryFile> Function(int offset, int limit) getElems, Isar to) {
    from.writeTxnSync(() {
      var offset = 0;

      for (;;) {
        var sorted = getElems(offset, 40);
        offset += 40;

        for (var element in sorted) {
          element.isarId = null;
        }

        to.writeTxnSync(() => to.directoryFiles.putAllSync(sorted));

        if (sorted.length != 40) {
          break;
        }
      }
    });
  }

  @override
  void close() {
    imageIsar.close(deleteFromDisk: true);
    filter.dispose();
  }

  _ImagesImpl(this.imageIsar, this.client, this.d);

  @override
  Future<int> refresh() async {
    imageIsar.writeTxnSync(() => imageIsar.clearSync());
    reachedEnd = false;
    page = 0;

    for (;;) {
      if (await _nextImages()) {
        break;
      }
    }

    var copy = openServerApiInnerIsar();

    _writeFromTo(imageIsar, (offset, limit) {
      return imageIsar.directoryFiles
          .where()
          .sortByTimeDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    }, copy);

    imageIsar.close(deleteFromDisk: true);

    imageIsar = copy;
    filter.setFrom(imageIsar);

    return imageIsar.directoryFiles.countSync();
  }

  @override
  Future uploadFiles(List<PlatformFile> l, void Function() onDone) {
    if (l.isEmpty) {
      throw "l is empty";
    }

    Uploader().add(Uri.parse(d.serverUrl),
        l.map((e) => FileAndDir(d.dirPath, e)).toList(), onDone);

    return Future.value();
  }

  @override
  Future deleteFiles(List<DirectoryFile> f, void Function() onDone) async {
    var resp = await client.postUri(
        Uri.parse(d.serverUrl).replace(path: "/delete/files"),
        options:
            Options(headers: _deviceId(), contentType: Headers.jsonContentType),
        data: jsonEncode(f.map((e) => joinAll([e.dir, e.name])).toList()));
    if (resp.statusCode != 200) {
      throw resp.data;
    }

    onDone();
  }
}

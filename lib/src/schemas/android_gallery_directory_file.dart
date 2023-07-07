import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

part 'android_gallery_directory_file.g.dart';

@collection
class SystemGalleryDirectoryFile implements Cell<void> {
  Id? isarId;

  @Index(unique: true)
  String id;
  String directoryId;
  String name;
  List<byte> thumbnail;
  int lastModified;
  String originalUri;

  SystemGalleryDirectoryFile(
      {required this.id,
      required this.directoryId,
      required this.name,
      required this.lastModified,
      required this.originalUri,
      required this.thumbnail});

  @ignore
  @override
  List<Widget>? Function() get addButtons => () {
        return null;
      };

  @ignore
  @override
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo => (
            _,
            __,
            ___,
          ) {
            return null;
          };

  @override
  String alias(bool isList) => name;

  @override
  Content fileDisplay() {
    return Content(ContentType.image, true,
        image: FileImage(File(originalUri)));
  }

  @override
  String fileDownloadUrl() => "";

  @override
  CellData getCellData(bool isList) {
    return CellData(
        thumb: MemoryImage(thumbnail as Uint8List), name: name, stickers: []);
  }

  @override
  void shrinkedData() {
    // TODO: implement shrinkedData
  }
}

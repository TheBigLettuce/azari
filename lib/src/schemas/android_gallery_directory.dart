import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:transparent_image/transparent_image.dart';

import '../cell/cell.dart';
import 'android_gallery_directory_file.dart';

part 'android_gallery_directory.g.dart';

@collection
class SystemGalleryDirectory implements Cell<String> {
  @override
  Id? isarId;

  int thumbFileId;
  @Index(unique: true)
  String bucketId;

  @Index()
  String name;

  @Index()
  int lastModified;

  SystemGalleryDirectory(
      {required this.bucketId,
      required this.name,
      required this.lastModified,
      required this.thumbFileId});

  @ignore
  @override
  List<Widget>? Function() get addButtons => () => null;

  @ignore
  @override
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo => (_, __, ___) {
            return null;
          };

  @override
  String alias(bool isList) => name;

  @override
  Content fileDisplay() => throw "not implemented";

  @override
  String fileDownloadUrl() => "";

  @override
  CellData getCellData(bool isList) {
    ImageProvider provier;
    var record = androidThumbnail(thumbFileId);
    try {
      provier = KeyMemoryImage(bucketId, record.$1);
    } catch (e) {
      provier = MemoryImage(kTransparentImage);
    }

    return CellData(
        thumb: provier, name: name, stickers: [], loaded: record.$2);
  }

  @override
  String shrinkedData() {
    return bucketId;
  }
}

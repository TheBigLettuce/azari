import 'package:flutter/material.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:isar/isar.dart';
import 'package:transparent_image/transparent_image.dart';

import '../cell/cell.dart';
import 'android_gallery_directory_file.dart';

part 'android_gallery_directory.g.dart';

class SystemGalleryDirectoryShrinked {
  final String name;
  final String bucketId;
  final String relativeLoc;

  const SystemGalleryDirectoryShrinked(
      {required this.bucketId, required this.name, required this.relativeLoc});
}

@collection
class SystemGalleryDirectory implements Cell<SystemGalleryDirectoryShrinked> {
  @override
  Id? isarId;

  final int thumbFileId;
  @Index(unique: true)
  final String bucketId;

  @Index()
  final String name;

  final String relativeLoc;

  @Index()
  final int lastModified;

  SystemGalleryDirectory(
      {required this.bucketId,
      required this.name,
      required this.relativeLoc,
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
  Contentable fileDisplay() => const EmptyContent();

  @override
  String fileDownloadUrl() => "";

  @override
  CellData getCellData(bool isList) {
    ImageProvider provier;
    var record = androidThumbnail(thumbFileId);
    try {
      provier =
          KeyMemoryImage(bucketId + record.$1.length.toString(), record.$1);
    } catch (e) {
      provier = MemoryImage(kTransparentImage);
    }

    return CellData(
        thumb: provier, name: name, stickers: [], loaded: record.$2);
  }

  @override
  SystemGalleryDirectoryShrinked shrinkedData() {
    return SystemGalleryDirectoryShrinked(
        name: name, bucketId: bucketId, relativeLoc: relativeLoc);
  }
}

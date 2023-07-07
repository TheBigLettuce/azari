import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:transparent_image/transparent_image.dart';

import '../cell/cell.dart';

part 'android_gallery_directory.g.dart';

@collection
class SystemGalleryDirectory implements Cell<void> {
  Id? get isarId => fastHash(id);

  @Index(unique: true)
  String id;

  @Index()
  String name;

  List<byte> thumbnail;

  int lastModified;

  SystemGalleryDirectory(
      {required this.id,
      required this.thumbnail,
      required this.name,
      required this.lastModified});

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
    try {
      provier = MemoryImage(thumbnail as Uint8List);
    } catch (e) {
      provier = MemoryImage(kTransparentImage);
    }

    return CellData(thumb: provier, name: name, stickers: []);
  }

  @override
  void shrinkedData() {
    // TODO: implement shrinkedData
  }
}

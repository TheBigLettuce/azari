import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';

import 'data.dart';

class ImageCell extends Cell {
  Uint8List thumb;
  AssetEntity entity;
  String? videoUri;

  @override
  Content fileDisplay() {
    var type = entity.mimeType!.split("/")[0];

    if (type == "image") {
      return Content(type, true, image: AssetEntityImageProvider(entity));
    } else if (type == "video") {
      return Content(type, true, videoPath: videoUri);
    } else {
      return Content(type, false);
    }
  }

  @override
  CellData getCellData() => CellData(
      thumb: () {
        return MemoryImage(thumb);
      },
      name: super.alias);

  ImageCell({
    this.videoUri,
    required this.thumb,
    required this.entity,
    required super.addButtons,
    required super.addInfo,
    required super.alias,
    required super.path,
  });
}

class Content {
  String type;
  bool isVideoLocal;

  ImageProvider? image;

  String? videoPath;

  Content(this.type, this.isVideoLocal, {this.image, this.videoPath});
}

class Cell {
  String path;
  String alias;

  List<Widget>? Function(dynamic extra) addInfo;

  List<Widget>? Function() addButtons;

  Content fileDisplay() => throw "not implemented";

  String fileDownloadUrl() => path;

  CellData getCellData() => throw "not implemented";

  Cell(
      {required this.path,
      required this.alias,
      required this.addInfo,
      required this.addButtons});
}

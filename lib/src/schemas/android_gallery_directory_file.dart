import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/directory_file.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/thumbnail.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:transparent_image/transparent_image.dart';

part 'android_gallery_directory_file.g.dart';

@collection
class SystemGalleryDirectoryFile implements Cell<void> {
  @override
  Id? isarId;

  @Index(unique: true)
  final int id;
  final String bucketId;
  @Index()
  final String name;
  @Index()
  final int lastModified;
  final String originalUri;

  final int height;
  final int width;

  final bool isVideo;
  final bool isGif;

  SystemGalleryDirectoryFile({
    required this.id,
    required this.bucketId,
    required this.name,
    required this.isVideo,
    required this.isGif,
    required this.height,
    required this.width,
    required this.lastModified,
    required this.originalUri,
  });

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
            context,
            extra,
            colors,
          ) {
            return [
              addInfoTile(
                  colors: colors,
                  title: "Name",
                  subtitle: name), // TODO: change
              addInfoTile(
                  colors: colors,
                  title: "Last modified",
                  subtitle: lastModified.toString()), // TODO: change
              ...makeTags(
                  context, extra, colors, PostTags().getTagsPost(name), null)
            ];
          };

  @override
  String alias(bool isList) => name;

  @override
  Content fileDisplay() {
    if (isVideo) {
      return Content(ContentType.video, true, videoPath: originalUri);
    }

    if (isGif) {
      return Content(ContentType.androidGif, true,
          androidUri: originalUri,
          size: Size(width.toDouble(), height.toDouble()));
    }

    return Content(ContentType.androidImage, true,
        androidUri: originalUri,
        size: Size(width.toDouble(), height.toDouble()));
  }

  @override
  String fileDownloadUrl() => "";

  @override
  CellData getCellData(bool isList) {
    var record = androidThumbnail(id);

    return CellData(
        thumb: KeyMemoryImage(
            id.toString() + record.$1.length.toString(), record.$1),
        name: name,
        stickers: [
          if (isVideo) Icons.play_circle,
          if (isGif) Icons.gif_box_outlined
        ],
        loaded: record.$2);
  }

  @override
  void shrinkedData() {
    // TODO: implement shrinkedData
  }
}

(Uint8List, bool) androidThumbnail(int id) {
  var thumb = thumbnailIsar().thumbnails.getSync(id);
  return thumb == null
      ? (kTransparentImage, false)
      : (thumb.data as Uint8List, true);
}

class KeyMemoryImage extends ImageProvider<MemoryImage> {
  final String key;
  final Uint8List bytes;

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) {
    return Future.value(MemoryImage(bytes));
  }

  @override
  ImageStreamCompleter loadBuffer(
      ImageProvider key, DecoderBufferCallback decode) {
    return key.loadBuffer(key, decode);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is KeyMemoryImage && other.key == key;
  }

  const KeyMemoryImage(this.key, this.bytes);

  @override
  int get hashCode => key.hashCode;
}

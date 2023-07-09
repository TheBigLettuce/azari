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
  int id;
  String bucketId;
  @Index()
  String name;
  @Index()
  int lastModified;
  String originalUri;

  bool isVideo;

  SystemGalleryDirectoryFile({
    required this.id,
    required this.bucketId,
    required this.name,
    required this.isVideo,
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

    ImageProvider provider;
    var path = joinAll([temporaryImagesDir(), split(originalUri).last]);
    if (File(path).existsSync()) {
      if (File(path).lengthSync() == 0) {
        provider = MemoryImage(kTransparentImage);
      } else {
        provider = FileImage(File(path));
      }
    } else {
      provider = _PlatformImage(originalUri);
    }

    return Content(ContentType.image, true, image: provider);
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
        stickers: [if (isVideo) Icons.play_circle],
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

void loadNextImage(String originalUri) {
  if (File(joinAll([temporaryImagesDir(), split(originalUri).last]))
      .existsSync()) {
    return;
  }
  const MethodChannel channel = MethodChannel("lol.bruh19.azari.gallery");
  channel.invokeMethod("moveFromMediaStore", {
    "from": originalUri,
    "to": temporaryImagesDir(),
  });
}

class _PlatformImage extends ImageProvider<ImageProvider> {
  final String path;

  @override
  Future<ImageProvider> obtainKey(ImageConfiguration configuration) async {
    const MethodChannel channel = MethodChannel("lol.bruh19.azari.gallery");
    try {
      var p = joinAll([temporaryImagesDir(), split(path).last]);
      if (File(p).existsSync()) {
        return FileImage(File(p));
      }
      String resp = await channel.invokeMethod("moveFromMediaStore", {
        "from": path,
        "to": temporaryImagesDir(),
      });

      if (File(resp).lengthSync() == 0) {
        return MemoryImage(kTransparentImage);
      }

      return FileImage(File(resp));
    } catch (e) {
      log("copy file", level: Level.SEVERE.value, error: e);
      return MemoryImage(kTransparentImage);
    }
  }

  @override
  ImageStreamCompleter loadBuffer(
      ImageProvider key, DecoderBufferCallback decode) {
    return key.loadBuffer(key, decode);
  }

  const _PlatformImage(this.path);
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

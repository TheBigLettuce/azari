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
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'android_gallery_directory_file.g.dart';

class SystemGalleryDirectoryFileShrinked {
  final int id;
  final String originalUri;
  final bool isVideo;

  const SystemGalleryDirectoryFileShrinked(
      this.id, this.originalUri, this.isVideo);
}

@collection
class SystemGalleryDirectoryFile
    implements Cell<SystemGalleryDirectoryFileShrinked> {
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

  bool _isDuplicate() {
    return RegExp(r'[(][0-9].*[)][.][a-zA-Z].*').hasMatch(name);
  }

  @ignore
  @override
  List<Widget>? Function() get addButtons => () {
        return _isDuplicate()
            ? [const Icon(Icons.mode_standby_outlined)]
            : null;
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
                  title: AppLocalizations.of(context)!.nameTitle,
                  subtitle: name),
              addInfoTile(
                  colors: colors,
                  title: AppLocalizations.of(context)!.dateModified,
                  subtitle: lastModified.toString()),
              ...makeTags(
                  context, extra, colors, PostTags().getTagsPost(name), null)
            ];
          };

  @override
  String alias(bool isList) => name;

  @override
  Contentable fileDisplay() {
    final size = Size(width.toDouble(), height.toDouble());

    if (isVideo) {
      return AndroidVideo(uri: originalUri, size: size);
    }

    if (isGif) {
      return AndroidGif(
          uri: originalUri, size: Size(width.toDouble(), height.toDouble()));
    }

    return AndroidImage(
        uri: originalUri, size: Size(width.toDouble(), height.toDouble()));
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
          if (_isDuplicate()) Icons.mode_standby_outlined,
          if (isGif) Icons.gif_box_outlined
        ],
        loaded: record.$2);
  }

  @override
  SystemGalleryDirectoryFileShrinked shrinkedData() {
    return SystemGalleryDirectoryFileShrinked(id, originalUri, isVideo);
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
      ImageProvider key,
      // ignore: deprecated_member_use
      DecoderBufferCallback decode) {
    // ignore: deprecated_member_use
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

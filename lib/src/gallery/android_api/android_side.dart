import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/android_api/api.g.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/blacklisted_directory.dart';
import 'package:gallery/src/schemas/gallery_last_modified.dart';
import 'package:gallery/src/schemas/thumbnail.dart';
import 'package:isar/isar.dart';

import 'interface_impl.dart';

class GalleryImpl implements GalleryApi {
  final Isar db;

  @override
  void finish(String version) {
    db.writeTxnSync(
        () => db.galleryLastModifieds.putSync(GalleryLastModified(version)));
  }

  final AndroidGallery androidGalleryApi;

  factory GalleryImpl.instance() => _global!;

  factory GalleryImpl(AndroidGallery impl) {
    if (_global != null) {
      return _global!;
    }

    _global = GalleryImpl._new(impl, openAndroidGalleryIsar());
    return _global!;
  }

  GalleryImpl._new(this.androidGalleryApi, this.db);

  @override
  void updatePictures(
      List<DirectoryFile?> f, String bucketId, int startTime, bool inRefresh) {
    if (f.isEmpty) {
      return;
    }

    var st = androidGalleryApi.currentImages?.startTime;

    if (st == null || st > startTime) {
      return;
    }

    if (androidGalleryApi.currentImages?.bucketId != bucketId) {
      return;
    }

    var db = androidGalleryApi.currentImages?.db;
    if (db == null) {
      return;
    }

    db.writeTxnSync(() => db.systemGalleryDirectoryFiles.putAllSync(f
        .cast<DirectoryFile>()
        .map((e) => SystemGalleryDirectoryFile(
            id: e.id,
            bucketId: e.bucketId,
            name: e.name,
            lastModified: e.lastModified,
            height: e.height,
            width: e.width,
            isGif: e.isGif,
            originalUri: e.originalUri,
            isVideo: e.isVideo))
        .toList()));
    var callback = androidGalleryApi.currentImages?.callback;
    if (callback != null) {
      callback(db.systemGalleryDirectoryFiles.countSync(), inRefresh);
    }
  }

  @override
  void addThumbnails(List<ThumbnailId?> thumbs) {
    if (thumbs.isEmpty) {
      return;
    }

    if (thumbnailIsar().thumbnails.countSync() >= 3000) {
      thumbnailIsar().writeTxnSync(() => thumbnailIsar()
          .thumbnails
          .where()
          .sortByUpdatedAt()
          .limit(thumbs.length)
          .deleteAllSync());
    }

    thumbnailIsar().writeTxnSync(() {
      thumbnailIsar().thumbnails.putAllSync(thumbs
          .cast<ThumbnailId>()
          .map((e) => Thumbnail(e.id, DateTime.now(), e.thumb))
          .toList());
    });
  }

  @override
  List<int?> thumbsExist(List<int?> ids) {
    List<int> response = [];
    for (final id in ids.cast<int>()) {
      if (thumbnailIsar().thumbnails.where().idEqualTo(id).countSync() != 1) {
        response.add(id);
      }
    }

    return response;
  }

  @override
  void updateDirectories(List<Directory?> d, bool inRefresh) {
    var blacklisted = db.blacklistedDirectorys
        .where()
        .anyOf(d.cast<Directory>(),
            (q, element) => q.bucketIdEqualTo(element.bucketId))
        .findAllSync();
    final map = <String, void>{for (var i in blacklisted) i.bucketId: Null};
    d = List.from(d);
    d.removeWhere((element) => map.containsKey(element!.bucketId));

    db.writeTxnSync(() {
      db.systemGalleryDirectorys.putAllSync(d
          .cast<Directory>()
          .map((e) => SystemGalleryDirectory(
              bucketId: e.bucketId,
              name: e.name,
              thumbFileId: e.thumbFileId,
              lastModified: e.lastModified))
          .toList());
    });

    if (androidGalleryApi.callback != null) {
      androidGalleryApi.callback!(
          db.systemGalleryDirectorys.countSync(), inRefresh);
    }
  }
}

GalleryImpl? _global;

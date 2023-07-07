import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/android_api/api.g.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/gallery_last_modified.dart';
import 'package:isar/isar.dart';

import 'interface_impl.dart';

class GalleryImpl implements GalleryApi {
  final Isar db = openAndroidGalleryIsar();

  @override
  bool compareTime(String id, int time) {
    // TODO: implement compareTime
    throw UnimplementedError();
  }

  @override
  void finish(String version) {
    db.writeTxnSync(
        () => db.galleryLastModifieds.putSync(GalleryLastModified(version)));
  }

  @override
  String start() {
    return db.galleryLastModifieds.getSync(0)?.version ?? "";
  }

  @override
  void updateDirectory(Directory d) {
    db.writeTxnSync(() => db.systemGalleryDirectorys.putByIdSync(
        SystemGalleryDirectory(
            thumbnail: d.thumbnail.cast(),
            id: d.id,
            name: d.name,
            lastModified: d.lastModified)));

    if (androidGalleryApi.callback != null) {
      androidGalleryApi.callback!(db.systemGalleryDirectorys.countSync());
    }
  }

  @override
  void updatePicture(DirectoryFile f) {
    androidGalleryApi.currentImages?.db.writeTxnSync(() {
      androidGalleryApi.currentImages!.db.systemGalleryDirectoryFiles.putSync(
          SystemGalleryDirectoryFile(
              id: f.id,
              directoryId: f.directoryId,
              name: f.name,
              lastModified: f.lastModified,
              originalUri: f.originalUri,
              thumbnail: f.thumbnail));
      var callback = androidGalleryApi.currentImages?.callback;
      if (callback != null) {
        callback(androidGalleryApi.currentImages?.db.systemGalleryDirectoryFiles
                .countSync() ??
            0);
      }
    });
  }

  final AndroidGallery androidGalleryApi;

  factory GalleryImpl.instance() => _global!;

  factory GalleryImpl(AndroidGallery impl) {
    if (_global != null) {
      return _global!;
    }

    _global = GalleryImpl._new(impl);
    return _global!;
  }

  GalleryImpl._new(this.androidGalleryApi);

  @override
  void updatePictures(List<DirectoryFile?> f) {
    var db = androidGalleryApi.currentImages?.db;
    if (db == null) {
      return;
    }

    db.writeTxnSync(() => db.systemGalleryDirectoryFiles.putAllSync(f
        .cast<DirectoryFile>()
        .map((e) => SystemGalleryDirectoryFile(
            id: e.id,
            directoryId: e.directoryId,
            name: e.name,
            lastModified: e.lastModified,
            originalUri: e.originalUri,
            thumbnail: e.thumbnail))
        .toList()));
    var callback = androidGalleryApi.currentImages?.callback;
    if (callback != null) {
      callback(db.systemGalleryDirectoryFiles.countSync());
    }
  }
}

GalleryImpl? _global;

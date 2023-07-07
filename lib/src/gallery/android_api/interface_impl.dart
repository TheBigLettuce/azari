import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/gallery/android_api/android_side.dart';
import 'package:gallery/src/schemas/android_gallery_directory.dart';
import 'package:gallery/src/schemas/android_gallery_directory_file.dart';
import 'package:isar/isar.dart';

import '../interface.dart';

class AndroidGallery
    implements
        GalleryAPI<SystemGalleryDirectory, void, SystemGalleryDirectoryFile,
            void> {
  @override
  Dio get client => throw UnimplementedError();

  void Function(int i)? callback;
  AndroidGalleryFiles? currentImages;

  @override
  void close() {
    callback = null;
    currentImages = null;
  }

  @override
  Future delete(SystemGalleryDirectory d) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  SystemGalleryDirectory directCell(int i) =>
      GalleryImpl.instance().db.systemGalleryDirectorys.getSync(i + 1)!;

  @override
  Future<Result<SystemGalleryDirectory>> directories() {
    var db = GalleryImpl.instance().db;

    return Future.value(Result(
        (i) => db.systemGalleryDirectorys.getSync(i + 1)!,
        db.systemGalleryDirectorys.countSync()));
  }

  @override
  GalleryAPIFiles<SystemGalleryDirectoryFile, void> images(
      SystemGalleryDirectory d) {
    return AndroidGalleryFiles(openAndroidGalleryInnerIsar());
  }

  @override
  Future modify(SystemGalleryDirectory old, SystemGalleryDirectory newd) {
    // TODO: implement modify
    throw UnimplementedError();
  }

  @override
  Future newDirectory(String path, void Function() onDone) {
    // TODO: implement newDirectory
    throw UnimplementedError();
  }

  @override
  Future setThumbnail(String newThumb, SystemGalleryDirectory d) {
    // TODO: implement setThumbnail
    throw UnimplementedError();
  }

  AndroidGallery._new();
  factory AndroidGallery() {
    if (_global != null) {
      return _global!;
    }

    _global = AndroidGallery._new();
    return _global!;
  }
}

AndroidGallery? _global;

class AndroidGalleryFiles
    implements GalleryAPIFiles<SystemGalleryDirectoryFile, void> {
  Isar db;
  void Function(int i)? callback;

  @override
  void close() {
    db.close(deleteFromDisk: true);
    _global!.currentImages = null;
  }

  SystemGalleryDirectoryFile directCell(int i) =>
      db.systemGalleryDirectoryFiles.getSync(i + 1)!;

  @override
  Future delete(SystemGalleryDirectoryFile f) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future deleteFiles(List<void> f, void Function() onDone) {
    // TODO: implement deleteFiles
    throw UnimplementedError();
  }

  @override
  Result<SystemGalleryDirectoryFile> filter(String s) {
    // TODO: implement filter
    throw UnimplementedError();
  }

  @override
  // TODO: implement reachedEnd
  bool get reachedEnd => throw UnimplementedError();

  @override
  Future<Result<SystemGalleryDirectoryFile>> refresh() {
    return Future.value(Result(
        (i) => db.systemGalleryDirectoryFiles.getSync(i)!,
        db.systemGalleryDirectoryFiles.countSync()));
  }

  @override
  void resetFilter() {
    // TODO: implement resetFilter
  }

  @override
  Future uploadFiles(List<PlatformFile> l, void Function() onDone) {
    // TODO: implement uploadFiles
    throw UnimplementedError();
  }

  AndroidGalleryFiles(this.db);
}

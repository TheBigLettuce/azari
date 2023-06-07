import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';

class Result<T extends Cell> {
  final int count;
  final T Function(int i) cell;
  const Result(this.cell, this.count);
}

abstract class GalleryAPIFiles {
  bool get reachedEnd;

  Future<Result<DirectoryFile>> nextImages();
  Future<Result<DirectoryFile>> refresh();

  Future delete(DirectoryFile f);
  Future uploadFiles(List<PlatformFile> l);

  void close();
}

abstract class GalleryAPI {
  Dio get client;

  Future<Result<Directory>> directories();
  GalleryAPIFiles images(Directory d);

  Future delete(Directory d);
  Future newDirectory(String path);

  void close();
}

import 'package:flutter/material.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:isar/isar.dart';
import '../gallery/android_api/api.g.dart' as gallery;

part 'directory_file.g.dart';

@collection
class DirectoryFile implements Cell {
  Id? isarId;

  String dir;
  String name;
  String thumbHash;
  String origHash;
  int type;
  String host;

  @ignore
  @override
  List<Widget>? Function() get addButtons => () => null;

  @ignore
  @override
  List<Widget>? Function(BuildContext context, dynamic extra, Color borderColor,
          Color foregroundColor, Color systemOverlayColor)
      get addInfo => (_, __, ___, ____, _____) => null;

  @override
  String alias(bool isList) {
    return name;
  }

  @override
  Content fileDisplay() {
    return Content("image", true,
        image: NetworkImage(
            Uri.parse(host).replace(path: '/static/$origHash').toString()));
  }

  @override
  String fileDownloadUrl() {
    // TODO: implement fileDownloadUrl
    throw UnimplementedError();
  }

  @override
  CellData getCellData(bool isList) {
    return CellData(
        thumb: NetworkImage(
            Uri.parse(host).replace(path: '/static/$thumbHash').toString()),
        name: name);
  }

  DirectoryFile(this.dir,
      {required this.host,
      required this.name,
      required this.origHash,
      required this.thumbHash,
      required this.type});
}

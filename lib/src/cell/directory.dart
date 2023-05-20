import 'package:flutter/widgets.dart';

import 'cell.dart';
import 'data.dart';

class DirectoryCell extends Cell {
  ImageProvider image;
  String dirName;
  String id;

  @override
  String alias(bool isList) => dirName;

  @override
  Content fileDisplay() => throw "not implemented";

  @override
  String fileDownloadUrl() => path;

  @override
  CellData getCellData(bool isList) => CellData(
      thumb: () {
        return image;
      },
      name: alias(isList));

  DirectoryCell(
      {required this.image,
      required this.id,
      required super.path,
      required this.dirName,
      required super.addInfo,
      required super.addButtons});
}

import 'package:flutter/widgets.dart';

import 'cell.dart';
import 'data.dart';

class DirectoryCell extends Cell {
  ImageProvider image;
  String id;

  @override
  CellData getCellData() => CellData(
      thumb: () {
        return image;
      },
      name: super.alias);

  DirectoryCell(
      {required this.image,
      required this.id,
      required super.path,
      required super.alias,
      required super.addInfo,
      required super.addButtons});
}

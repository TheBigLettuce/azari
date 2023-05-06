import 'package:flutter/widgets.dart';

import 'data.dart';

class Cell {
  String path;
  String alias;

  List<Widget>? Function() addInfo;

  List<Widget>? Function() addButtons;

  String fileDownloadUrl() => path;

  String fileDisplayUrl() => path;

  CellData getCellData() => CellData(thumbUrl: path, name: alias);

  Cell(
      {required this.path,
      required this.alias,
      required this.addInfo,
      required this.addButtons});
}

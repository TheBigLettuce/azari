import 'package:flutter/widgets.dart';

import 'data.dart';

class Cell {
  String path;
  String alias;

  List<Widget>? Function() addInfo;

  String url() => path;

  Future<CellData> getFile() async {
    throw "unimplimented";
  }

  Cell({required this.path, required this.alias, required this.addInfo});
}

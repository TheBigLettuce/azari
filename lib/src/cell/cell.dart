import 'package:flutter/widgets.dart';

import 'data.dart';

class Content {
  String type;
  bool isVideoLocal;

  ImageProvider? image;

  String? videoPath;

  Content(this.type, this.isVideoLocal, {this.image, this.videoPath});
}

abstract class Cell {
  String path;

  String alias(bool isList);

  List<Widget>? Function(
      dynamic extra, Color borderColor, Color foregroundColor) addInfo;

  List<Widget>? Function() addButtons;

  Content fileDisplay();

  String fileDownloadUrl();

  CellData getCellData(bool isList);

  Cell({required this.path, required this.addInfo, required this.addButtons});
}

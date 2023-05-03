import 'package:flutter/widgets.dart';
import 'cell.dart';

class ImageCell extends Cell {
  List<Widget>? addInfo;

  String url() => "";

  ImageCell({required super.alias, required super.path, this.addInfo});
}

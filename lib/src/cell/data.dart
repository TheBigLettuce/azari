import 'package:flutter/widgets.dart';

class CellData {
  final ImageProvider Function() thumb;
  final String name;

  CellData({required this.thumb, required this.name});
}

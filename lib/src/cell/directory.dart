import 'cell.dart';

class DirectoryCell extends Cell {
  Future delete() async {}

  DirectoryCell({
    required super.path,
    required super.alias,
  });
}

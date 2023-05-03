import 'data.dart';

class Cell {
  String path;
  String alias;

  Future<CellData> getFile() async {
    throw "unimplimented";
  }

  Cell({required this.path, required this.alias});
}

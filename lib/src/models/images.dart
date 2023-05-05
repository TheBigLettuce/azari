import '../cell/cell.dart';
import 'core.dart';
import 'grid_list.dart';

class ImagesModel extends CoreModel with GridList<Cell> {
  String dir;

  void Function(List<Cell>)? onRefresh;

  @override
  Future<List<Cell>> fetchRes() async {
    throw "unimplimented";
  }

  @override
  Future delete(int indx) async {
    throw "unimplimented";
  }

  @override
  Future refresh() => super.refreshFuture(fetchRes(), onRefresh: onRefresh);

  void setOnRefresh(void Function(List<Cell> newList) onChange) =>
      onRefresh = onChange;

  ImagesModel({required this.dir});
}

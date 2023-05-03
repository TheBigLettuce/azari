import 'core.dart';
import '../cell/image.dart';
import 'grid_list.dart';

class ImagesModel extends CoreModel with GridList<ImageCell> {
  String dir;

  void Function(List<ImageCell>)? onRefresh;

  @override
  Future<List<ImageCell>> fetchRes() async {
    throw "unimplimented";
  }

  @override
  Future delete(int indx) async {
    throw "unimplimented";
  }

  @override
  Future refresh() => super.refreshFuture(fetchRes(), onRefresh: onRefresh);

  void setOnRefresh(void Function(List<ImageCell> newList) onChange) =>
      onRefresh = onChange;

  ImagesModel({required this.dir});
}

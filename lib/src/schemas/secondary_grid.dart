import 'package:isar/isar.dart';

part 'secondary_grid.g.dart';

@collection
class SecondaryGrid {
  Id id = 0;

  String tags;

  double scrollPositionGrid;

  int? selectedPost;
  double? scrollPositionTags;
  int? page;

  SecondaryGrid(this.tags, this.scrollPositionTags, this.selectedPost,
      this.scrollPositionGrid,
      {this.page});
}

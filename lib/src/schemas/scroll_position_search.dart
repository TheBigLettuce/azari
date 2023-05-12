import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

part 'scroll_position_search.g.dart';

@collection
class ScrollPositionTags extends ScrollPosition {
  String tags;

  ScrollPositionTags(super.pos, super.id, this.tags, {super.page});
}

class ScrollPosition {
  String id;

  Id get isarId => fastHash(id);

  double pos;

  int? page;

  ScrollPosition(this.pos, this.id, {this.page});
}

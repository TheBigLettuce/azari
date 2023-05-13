import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

part 'scroll_position.g.dart';

@collection
class ScrollPositionPrimary {
  String id;

  Id get isarId => fastHash(id);

  double pos;
  double? tagPos;

  int? page;

  ScrollPositionPrimary(this.pos, this.id, {this.page, this.tagPos});
}

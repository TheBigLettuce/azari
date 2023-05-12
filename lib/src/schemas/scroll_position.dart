import 'package:gallery/src/schemas/scroll_position_search.dart';
import 'package:isar/isar.dart';

part 'scroll_position.g.dart';

@collection
class ScrollPositionPrimary extends ScrollPosition {
  ScrollPositionPrimary(super.pos, super.id, {super.page});
}

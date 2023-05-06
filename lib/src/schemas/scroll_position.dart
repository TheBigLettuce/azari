import 'package:isar/isar.dart';

part 'scroll_position.g.dart';

@collection
class ScrollPosition {
  Id id = 0;

  double pos;

  ScrollPosition(this.pos);
}

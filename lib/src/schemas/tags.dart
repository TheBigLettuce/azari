import 'package:isar/isar.dart';

part 'tags.g.dart';

@collection
class LastTag {
  Id id = Isar.autoIncrement;

  final String tag;

  LastTag(this.tag);
}

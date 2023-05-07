import 'package:isar/isar.dart';

part 'tags.g.dart';

@collection
class LastTag {
  Id id = Isar.autoIncrement;

  DateTime date;

  @Index(unique: true, replace: true)
  final String tag;

  LastTag(this.tag) : date = DateTime.now();
}

import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

part 'local_tags.g.dart';

@collection
class LocalTags {
  Id get isarId => fastHash(filename);

  @Index(unique: true, replace: true)
  final String filename;

  final List<String> tags;

  LocalTags(this.filename, this.tags);
}

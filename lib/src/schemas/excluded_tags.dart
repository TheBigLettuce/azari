import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

part 'excluded_tags.g.dart';

@collection
class ExcludedTags extends Tags {
  ExcludedTags(super.domain, super.tags);
}

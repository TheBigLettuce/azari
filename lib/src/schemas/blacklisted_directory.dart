import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

part 'blacklisted_directory.g.dart';

@collection
class BlacklistedDirectory {
  Id get isarId => fastHash(bucketId);

  @Index(unique: true, replace: true)
  String bucketId;

  BlacklistedDirectory(this.bucketId);
}

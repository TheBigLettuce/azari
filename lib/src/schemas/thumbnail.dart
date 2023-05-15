import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

part 'thumbnail.g.dart';

@collection
class Thumbnail {
  Id? get isarId => fastHash(id);
  String id;
  List<int> data;
  DateTime updatedAt;

  Thumbnail(this.data, this.id, this.updatedAt);
}

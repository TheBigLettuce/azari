import 'package:isar/isar.dart';

part 'gallery_last_modified.g.dart';

@collection
class GalleryLastModified {
  final Id isarId = 0;

  final String version;
  const GalleryLastModified(this.version);
}

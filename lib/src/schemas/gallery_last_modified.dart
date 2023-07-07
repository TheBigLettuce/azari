import 'package:isar/isar.dart';

part 'gallery_last_modified.g.dart';

@collection
class GalleryLastModified {
  Id isarId = 0;

  String version;
  GalleryLastModified(this.version);
}

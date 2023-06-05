import 'package:isar/isar.dart';
import '../gallery/android_api/api.g.dart' as gallery;

part 'directory_file.g.dart';

@collection
class DirectoryFile extends gallery.DirectoryFile {
  Id? isarId;
  @Index(unique: true, replace: true)
  String fileId;

  DirectoryFile(this.fileId,
      {required String directoryId,
      required int lastModified,
      required List<int?> thumbnail,
      required String name})
      : super(
            directoryId: directoryId,
            lastModified: lastModified,
            thumbnail: thumbnail,
            name: name);
}

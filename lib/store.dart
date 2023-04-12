import 'package:isar/isar.dart';

//import 'package:image_picker/image_picker.dart';

import 'src/gallery.g.dart';
import 'schema.dart';

late Isar db;

class ApiImpl implements GalleryApi {
  @override
  Result add(String bucketId, String albumName, String path, List<int?> thumb) {
    if (thumb is! List<int>) {
      return Result(message: "thumbnail is empty");
    }

    db.writeTxnSync(() {
      final album = db.albums.getSync(fastHash(bucketId));
      if (album == null) {
        db.writeTxnSync(() {
          db.albums
              .putSync(Album(id: bucketId, pictures: [newPic(path, thumb)]));
        });
      } else {
        album.add(newPic(path, thumb));
        db.albums.put(album);
      }
    });

    return Result(ok: true);
  }
}

Picture newPic(String path, List<int> thumb) {
  final newPicture = Picture();
  newPicture.name = path;
  newPicture.thumb = thumb;

  return newPicture;
}

void prepareDB(String dir) async {
  db = await Isar.open([AlbumSchema]);
}

import '../cell/boorucell.dart';

abstract class BooruAPI {
  Future<List<Post>> page(int p, String tags);
}

class Post {
  final int id;

  final String md5;
  final String tags;

  final int width;
  final int height;

  final String fileUrl;
  final String previewUrl;
  final String sampleUrl;

  final String ext;

  BooruCell booruCell() => BooruCell(
      alias: id.toString(),
      path: previewUrl,
      originalUrl: sampleUrl,
      tags: tags);

  Post(
      {required this.height,
      required this.id,
      required this.md5,
      required this.tags,
      required this.width,
      required this.fileUrl,
      required this.previewUrl,
      required this.sampleUrl,
      required this.ext});
}

List<BooruCell> postsToCells(List<Post> l) {
  List<BooruCell> list = [];

  for (var element in l) {
    list.add(element.booruCell());
  }

  return list;
}

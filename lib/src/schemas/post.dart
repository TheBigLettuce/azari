import 'package:isar/isar.dart';

import '../cell/booru.dart';

part 'post.g.dart';

@collection
class Post {
  Id? isarId;

  @Index(unique: true, replace: true)
  final int id;

  final String md5;
  final String tags;

  final int width;
  final int height;

  final String fileUrl;
  final String previewUrl;
  final String sampleUrl;

  final String ext;

  String filename() => "$id - $md5$ext";

  BooruCell booruCell(void Function(String tag) onTagPressed) => BooruCell(
      alias: id.toString(),
      path: previewUrl,
      originalUrl: sampleUrl,
      tags: tags,
      onTagPressed: onTagPressed);

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

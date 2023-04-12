import 'package:isar/isar.dart';

part 'schema.g.dart';

@collection
class Album {
  String id;

  Id get isarId => fastHash(id);

  List<Picture> pictures = [];

  Album({required this.id, required this.pictures});
  void add(Picture picture) {
    pictures.add(picture);
  }
}

@embedded
class Picture {
  String? name;
  List<int>? thumb;
}

int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}

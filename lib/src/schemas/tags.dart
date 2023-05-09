import 'package:isar/isar.dart';

part 'tags.g.dart';

@collection
class LastTags extends Tags {
  LastTags(super.domain, super.tags);
}

class Tags {
  String domain;

  Id get isarId => fastHash(domain);

  List<String> tags;

  Tags(this.domain, this.tags);
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

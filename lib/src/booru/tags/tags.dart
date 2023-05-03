import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

class Tags {
  void addLatest(String t) {
    isar().writeTxnSync(() {
      isar().lastTags.putSync(LastTag(t));
    });
  }

  List<LastTag> getLatest() => isar().lastTags.where().findAllSync();
}

import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

class Tags {
  void addLatest(String t) {
    isar().writeTxnSync(() {
      isar().lastTags.putSync(LastTag(t));
    });
  }

  void deleteTag(int tagId) => isar().writeTxnSync(
        () => isar().lastTags.deleteSync(tagId),
      );

  List<String> getLatestStr() => getLatest()
      .map(
        (e) => e.tag,
      )
      .toList();

  List<LastTag> getLatest() =>
      isar().lastTags.where().sortByDateDesc().findAllSync();
}

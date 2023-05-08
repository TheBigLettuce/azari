import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';

class BooruTags {
  LastTags _booruTagsLatest() {
    var currentBooru = isar().settings.getSync(0)!.selectedBooru;
    var booruTags = isar().lastTags.getSync(fastHash(currentBooru.string));
    if (booruTags == null) {
      booruTags = LastTags(currentBooru.string, []);
      isar().writeTxnSync(() => isar().lastTags.putSync(booruTags!));
    }

    return booruTags;
  }

  ExcludedTags _booruTagsExcluded() {
    var currentBooru = isar().settings.getSync(0)!.selectedBooru;
    var booruTags = isar().excludedTags.getSync(fastHash(currentBooru.string));
    if (booruTags == null) {
      booruTags = ExcludedTags(currentBooru.string, []);
      isar().writeTxnSync(() => isar().excludedTags.putSync(booruTags!));
    }

    return booruTags;
  }

  int _sortTags(Tag t1, Tag t2) => t1.date.compareTo(t2.date);

  void addLatest(String t) {
    var booruTags = _booruTagsLatest();
    var tagsCopy = List<Tag>.from(booruTags.tags)
        .where((element) => element.tag != t)
        .toList();
    tagsCopy.add(Tag(tag: t));
    tagsCopy.sort(_sortTags);
    isar().writeTxnSync(() {
      isar().lastTags.putSync(LastTags(booruTags.domain, tagsCopy));
    });
  }

  void deleteTag(String tag) {
    var booruTags = _booruTagsLatest();
    var tags = booruTags.tags.where((element) => element.tag != tag).toList();
    tags.sort(_sortTags);

    isar().writeTxnSync(
        () => isar().lastTags.putSync(LastTags(booruTags.domain, tags)));
  }

  List<String> getLatest() =>
      _booruTagsLatest().tags.map((e) => e.tag).toList();

  void addExcluded(String t) {
    var booruTags = _booruTagsExcluded();
    var tagsCopy = List<Tag>.from(booruTags.tags)
        .where((element) => element.tag != t)
        .toList();
    tagsCopy.add(Tag(tag: t));
    tagsCopy.sort(_sortTags);
    isar().writeTxnSync(() =>
        isar().excludedTags.putSync(ExcludedTags(booruTags.domain, tagsCopy)));
  }

  void deleteExcludedTag(String tag) {
    var booruTags = _booruTagsExcluded();
    var tags = booruTags.tags.where((element) => element.tag != tag).toList();
    tags.sort(_sortTags);

    isar().writeTxnSync(() =>
        isar().excludedTags.putSync(ExcludedTags(booruTags.domain, tags)));
  }

  List<String> getExcluded() =>
      _booruTagsExcluded().tags.map((e) => e.tag).toList();
}

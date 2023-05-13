import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/settings.dart';
import 'package:gallery/src/schemas/tags.dart';

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

  void addLatest(String t) {
    var booruTags = _booruTagsLatest();
    List<String> tagsCopy = List.from(booruTags.tags);
    tagsCopy.remove(t);
    tagsCopy.add(t);

    isar().writeTxnSync(() {
      isar()
          .lastTags
          .putSync(LastTags(booruTags.domain, tagsCopy.reversed.toList()));
    });
  }

  void deleteTag(String tag) {
    var booruTags = _booruTagsLatest();
    List<String> tags = List.from(booruTags.tags);
    tags.remove(tag);

    isar().writeTxnSync(
        () => isar().lastTags.putSync(LastTags(booruTags.domain, tags)));
  }

  List<String> getLatest() => _booruTagsLatest().tags;

  void addExcluded(String t) {
    var booruTags = _booruTagsExcluded();
    List<String> tagsCopy = List.from(booruTags.tags);
    tagsCopy.remove(t);
    tagsCopy.add(t);

    isar().writeTxnSync(() => isar()
        .excludedTags
        .putSync(ExcludedTags(booruTags.domain, tagsCopy.reversed.toList())));
  }

  void deleteExcludedTag(String tag) {
    var booruTags = _booruTagsExcluded();
    List<String> tags = List.from(booruTags.tags);
    tags.remove(tag);

    isar().writeTxnSync(() =>
        isar().excludedTags.putSync(ExcludedTags(booruTags.domain, tags)));
  }

  List<String> getExcluded() => _booruTagsExcluded().tags;
}

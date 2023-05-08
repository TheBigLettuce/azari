import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0;

  int picturesPerRow;
  bool listViewBooru;

  String path;
  bool booruDefault;
  bool enableGallery;
  @enumerated
  Booru selectedBooru;
  @enumerated
  DisplayQuality quality;

  Settings(
      {required this.path,
      required this.booruDefault,
      required this.selectedBooru,
      required this.quality,
      required this.enableGallery,
      required this.listViewBooru,
      required this.picturesPerRow});
  Settings copy(
      {String? path,
      bool? enableGallery,
      bool? booruDefault,
      Booru? selectedBooru,
      DisplayQuality? quality,
      bool? listViewBooru,
      int? picturesPerRow}) {
    return Settings(
        path: path ?? this.path,
        enableGallery: enableGallery ?? this.enableGallery,
        booruDefault: booruDefault ?? this.booruDefault,
        selectedBooru: selectedBooru ?? this.selectedBooru,
        quality: quality ?? this.quality,
        listViewBooru: listViewBooru ?? this.listViewBooru,
        picturesPerRow: picturesPerRow ?? this.picturesPerRow);
  }

  Settings.empty()
      : path = "",
        booruDefault = true,
        selectedBooru = Booru.gelbooru,
        quality = DisplayQuality.sample,
        enableGallery = false,
        picturesPerRow = 2,
        listViewBooru = false;
}

enum Booru {
  gelbooru(string: "Gelbooru"),
  danbooru(string: "Danbooru");

  final String string;

  const Booru({required this.string});
}

enum DisplayQuality {
  original("Original"),
  sample("Sample");

  final String string;

  const DisplayQuality(this.string);
}

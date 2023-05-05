import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0;

  String path;
  bool scrollView;
  bool booruDefault;

  Settings(
      {required this.path,
      required this.scrollView,
      required this.booruDefault});
  Settings copy({String? path, bool? scrollView, bool? booruDefault}) {
    return Settings(
        path: path ?? this.path,
        scrollView: scrollView ?? this.scrollView,
        booruDefault: booruDefault ?? this.booruDefault);
  }

  Settings.empty()
      : path = "",
        scrollView = false,
        booruDefault = true;
}

import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 0;

  //String serverAddress;
  String path;
  //String deviceId;

  Settings({required this.path});

  Settings.empty() : path = "";
}

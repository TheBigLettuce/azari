import 'package:isar/isar.dart';

part 'server_settings.g.dart';

@collection
class ServerSettings {
  Id isarId = 0;

  String host;
  List<int> deviceId;

  ServerSettings({required this.host, required this.deviceId});
  ServerSettings.empty()
      : host = "",
        deviceId = [];

  ServerSettings copy({String? host, List<int>? deviceId}) => ServerSettings(
      host: host ?? this.host, deviceId: deviceId ?? this.deviceId);
}

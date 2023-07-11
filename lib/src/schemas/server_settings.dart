import 'package:isar/isar.dart';

part 'server_settings.g.dart';

@collection
class ServerSettings {
  final Id isarId = 0;

  final String host;
  final List<byte> deviceId;

  const ServerSettings({required this.host, required this.deviceId});
  const ServerSettings.empty()
      : host = "",
        deviceId = const [];

  ServerSettings copy({String? host, List<int>? deviceId}) => ServerSettings(
      host: host ?? this.host, deviceId: deviceId ?? this.deviceId);
}

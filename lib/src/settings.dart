import 'package:flutter/material.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/settings.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    var settings = isar().settings.getSync(0);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(children: [
        ListTile(
          title: const Text("Device ID"),
          subtitle: Text(settings!.deviceId),
        ),
        ListTile(
          title: const Text("Default Directory"),
          subtitle: Text(settings.path),
        ),
        ListTile(
          title: const Text("Server Address"),
          subtitle: Text(settings.serverAddress),
        )
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(children: [
        ListTile(
          title: const Text("Device ID"),
          subtitle: Text(Hive.box("settings").get("deviceId")),
        ),
        ListTile(
          title: const Text("Default Directory"),
          subtitle: Text(Hive.box("settings").get("directory")),
        ),
        ListTile(
          title: const Text("Server Address"),
          subtitle: Text(Hive.box("settings").get("serverAddress")),
        )
      ]),
    );
  }
}

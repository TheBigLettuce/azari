import 'package:flutter/material.dart';
import 'package:gallery/src/drawer.dart';
import 'package:gallery/src/schemas/settings.dart';

import 'db/isar.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  @override
  Widget build(BuildContext context) {
    var settings = isar().settings.getSync(0)!;
    return Scaffold(
      appBar: AppBar(title: const Text("Debug")),
      drawer:
          makeDrawer(context, settings.booruDefault && !settings.enableGallery),
    );
  }
}

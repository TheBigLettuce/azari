import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../schemas/settings.dart';

Isar? _isar;
bool _initalized = false;

Future initalizeIsar() async {
  if (_initalized) {
    return;
  }
  _initalized = true;

  return Isar.open([SettingsSchema, LastTagSchema],
          directory: (await getApplicationSupportDirectory()).path,
          inspector: false)
      .then((value) {
    _isar = value;
  });
}

Isar isar() => _isar!;

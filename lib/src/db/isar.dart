import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/grid_restore.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart';
import 'package:gallery/src/schemas/secondary_grid.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../schemas/settings.dart';

Isar? _isar;
late String _directoryPath;
//Isar? _isarCopy;
bool _initalized = false;

/// [getBooru] returns a selected *booru API.
/// Some *booru have no way to retreive posts down
/// of a post number, in this case [page] comes in handy:
/// that is, it makes refreshes on restore few.
BooruAPI getBooru({int? page}) {
  var settings = isar().settings.getSync(0);
  if (settings!.selectedBooru == Booru.danbooru) {
    return Danbooru();
  } else if (settings.selectedBooru == Booru.gelbooru) {
    return Gelbooru(page ?? 0);
  } else {
    throw "invalid booru";
  }
}

Future initalizeIsar() async {
  if (_initalized) {
    return;
  }
  _initalized = true;

  _directoryPath = (await getApplicationSupportDirectory()).path;

  await Isar.open([
    SettingsSchema,
    LastTagsSchema,
    FileSchema,
    PostSchema,
    ScrollPositionPrimarySchema,
    ExcludedTagsSchema,
    GridRestoreSchema
  ], directory: _directoryPath, inspector: false)
      .then((value) {
    _isar = value;
  });
}

Isar isar() => _isar!;

Isar restoreIsarGrid(String path) {
  print("opening: $path");
  return Isar.openSync([PostSchema, SecondaryGridSchema],
      directory: _directoryPath, inspector: false, name: path);
}

Future<Isar> newSecondaryGrid() async {
  var p = DateTime.now().millisecondsSinceEpoch.toString();

  isar().writeTxnSync(() => isar().gridRestores.putSync(GridRestore(p)));

  return Isar.open([PostSchema, SecondaryGridSchema],
      directory: _directoryPath, inspector: false, name: p);
}

void removeSecondaryGrid(String name) {
  var grid = isar().gridRestores.filter().pathEqualTo(name).findFirstSync();
  if (grid != null) {
    var db = Isar.getInstance(grid.path);
    if (db != null) {
      db.close(deleteFromDisk: true);
    }
    isar().writeTxnSync(() => isar().gridRestores.deleteSync(grid.id!));
  }
}

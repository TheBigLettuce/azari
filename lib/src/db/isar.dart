import 'package:flutter/material.dart';
import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/grid_restore.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart';
import 'package:gallery/src/schemas/secondary_grid.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_storage/saf.dart';
import '../booru/infinite_scroll.dart';
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

void restoreState(BuildContext context, bool pushBooru) {
  if (pushBooru) {
    Navigator.pushReplacementNamed(context, "/booru");
  }
  var toRestore = isar().gridRestores.where().sortByDateDesc().findAllSync();

  _restoreState(context, toRestore, true);
}

void _restoreState(
    BuildContext context, List<GridRestore> toRestore, bool push) {
  if (toRestore.isEmpty) {
    if (!push) {
      Navigator.pop(context);
    }
    return;
  }

  for (true;;) {
    var restore = toRestore.removeAt(0);

    var isarR = restoreIsarGrid(restore.path);

    var state = isarR.secondaryGrids.getSync(0);

    if (state == null) {
      removeSecondaryGrid(isarR.name);
      continue;
    }

    var page = MaterialPageRoute(
      builder: (context) {
        return BooruScroll.restore(
          isar: isarR,
          tags: state.tags,
          initalScroll: state.scrollPositionGrid,
          pageViewScrollingOffset: state.scrollPositionTags,
          initalPost: state.selectedPost,
          booruPage: state.page,
        );
      },
    );

    if (push) {
      Navigator.push(context, page);
    } else {
      Navigator.pushReplacement(
        context,
        page,
      );
    }

    break;
  }
}

void restoreStateNext(BuildContext context, String exclude) {
  var toRestore = isar()
      .gridRestores
      .where()
      .pathNotEqualTo(exclude)
      .sortByDateDesc()
      .findAllSync();

  _restoreState(context, toRestore, false);
}

Isar isar() => _isar!;

Isar openDirectoryIsar() {
  return Isar.openSync([DirectorySchema],
      directory: _directoryPath, inspector: false, name: "directories");
}

void closeDirectoryIsar() {
  var instance = Isar.getInstance("directories");
  if (instance != null) {
    instance.close();
  }
}

Isar restoreIsarGrid(String path) {
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

Future<void> chooseDirectory(void Function(String) onError) async {
  var settings = isar().settings.getSync(0) ?? Settings.empty();

  var pickedDir = await openDocumentTree();
  if (pickedDir == null) {
    onError("Please choose a directory");
    return;
  }
  var perm = await persistedUriPermissions();
  if (perm == null || perm.isEmpty) {
    onError("Cannot write in current directory.");
    return;
  }

  var exist = false;

  for (var element in perm) {
    if (element.uri == pickedDir) {
      exist = true;
      break;
    }
  }

  if (!exist) {
    onError("Cannot write in current directory");
  }

  /*var canw = await (await pickedDir.toDocumentFile())!.canWrite();
  if (canw ?? false) {
    onError("Cannot write in the current directory");
    return;
  }*/

  isar().writeTxnSync(
    () {
      isar().settings.putSync(settings.copy(path: pickedDir.toString()));
    },
  );

  return Future.value();
}

import 'package:dio/dio.dart';
import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart';
import 'package:gallery/src/schemas/scroll_position_search.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../schemas/settings.dart';

Isar? _isar;
Isar? _isarCopy;
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

  await Isar.open([
    SettingsSchema,
    LastTagsSchema,
    FileSchema,
    PostSchema,
    ScrollPositionPrimarySchema,
    ExcludedTagsSchema,
    ScrollPositionTagsSchema
  ], directory: (await getApplicationSupportDirectory()).path, inspector: false)
      .then((value) {
    _isar = value;
  });

  return Isar.open([PostSchema],
          directory: (await getApplicationSupportDirectory()).path,
          inspector: false,
          name: "postsOnly")
      .then((value) {
    _isarCopy = value;
    /*_isarCopy!.writeTxnSync(() {
      _isarCopy!.posts.clearSync();
    });*/
  });
}

Isar isar() => _isar!;
Isar isarPostsOnly() => _isarCopy!;

import 'package:dio/dio.dart';
import 'package:gallery/src/booru/api/danbooru.dart';
import 'package:gallery/src/booru/api/gelbooru.dart';
import 'package:gallery/src/booru/interface.dart';
import 'package:gallery/src/schemas/download_file.dart';
import 'package:gallery/src/schemas/excluded_tags.dart';
import 'package:gallery/src/schemas/post.dart';
import 'package:gallery/src/schemas/scroll_position.dart';
import 'package:gallery/src/schemas/tags.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../schemas/settings.dart';

Isar? _isar;
Isar? _isarCopy;
bool _initalized = false;
Map<int, CancelToken> _tokens = {};

void addToken(int key, CancelToken t) => _tokens[key] = t;

void cancelAndRemoveToken(int key) {
  var t = _tokens[key];
  if (t == null) {
    return;
  }

  t.cancel();
  _tokens.remove(key);
}

BooruAPI getBooru() {
  var settings = isar().settings.getSync(0);
  if (settings!.selectedBooru == Booru.danbooru) {
    return Danbooru();
  } else if (settings.selectedBooru == Booru.gelbooru) {
    return Gelbooru();
  } else {
    throw "invalid booru";
  }
}

void removeToken(int key) => _tokens.remove(key);

bool hasCancelKey(int id) => _tokens[id] != null;

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
    ScrollPositionSchema,
    ExcludedTagsSchema,
  ], directory: (await getApplicationSupportDirectory()).path, inspector: false)
      .then((value) {
    _isar = value;
  });

  return Isar.open([PostSchema, ScrollPositionSchema],
          directory: (await getApplicationSupportDirectory()).path,
          inspector: false,
          name: "postsOnly")
      .then((value) {
    _isarCopy = value;
    _isarCopy!.writeTxnSync(() {
      _isarCopy!.posts.clearSync();
    });
  });
}

Isar isar() => _isar!;
Isar isarPostsOnly() => _isarCopy!;

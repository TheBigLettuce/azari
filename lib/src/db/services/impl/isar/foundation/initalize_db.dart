// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../impl.dart";

bool _initalized = false;

const mainSchemas = [
  IsarVisitedPostSchema,
  IsarSettingsSchema,
  IsarFavoritePostSchema, // TODO:
  IsarLocalTagDictionarySchema,
  IsarBookmarkSchema,
  IsarDownloadFileSchema,
  IsarHiddenBooruPostSchema,
  IsarStatisticsGallerySchema,
  IsarStatisticsGeneralSchema,
  IsarStatisticsBooruSchema,
  IsarDailyStatisticsSchema,
  IsarVideoSettingsSchema,
  IsarMiscSettingsSchema,
  IsarGridSettingsBooruSchema,
  IsarGridSettingsDirectoriesSchema,
  IsarGridSettingsFavoritesSchema,
  IsarGridSettingsFilesSchema,
  IsarGridSettingsAnimeDiscoverySchema,
];

// Future<void> _runIsolate((String, SendPort) value) async {
//   final (directory, port) = value;

//   try {
//     final favoritePostDb = Isar.openSync(
//       mainSchemas,
//       directory: directory,
//       inspector: false,
//       name: "favoritePosts",
//     );

//     List<IsarFavoritePost> list = [];

//     try {
//       for (final e in _IsarCollectionReverseIterable(
//         _IsarCollectionIterator(
//           favoritePostDb.isarFavoritePosts,
//           reversed: false,
//           bufferLen: 100,
//         ),
//       )) {
//         list.add(e);
//         if (list.length == 100) {
//           port.send(List<IsarFavoritePost>.unmodifiable(list));
//           list = [];
//         }
//       }

//       if (list.isNotEmpty) {
//         port.send(List<IsarFavoritePost>.unmodifiable(list));
//         list = const [];
//       }
//       port.send(const []);
//     } catch (e) {
//       if (kDebugMode) {
//         print(e);
//       }
//     }

//     await favoritePostDb.close();
//   } catch (e) {
//     if (kDebugMode) {
//       print(e);
//     }
//   }
// }

// Future<void> _favoritesLoop(
//   ServicesImplTable db,
//   Isolate isolate,
//   String directoryPath,
// ) async {
//   await for (final e in port) {
//     final list = e as List<dynamic>;
//     db.favoritePosts.backingStorage.addAll(list.cast<IsarFavoritePost>(), true);

//     if (e.isEmpty) {
//       db.favoritePosts.backingStorage.addAll(<IsarFavoritePost>[]);
//       break;
//     }
//   }

//   // isolate.kill();
// }

Future<DownloadManager> initalizeIsarDb(
  bool temporary,
  ServicesImplTable db,
  String appSupportDir,
  String temporaryDir,
) async {
  if (_initalized) {
    return throw "already initalized";
  }

  _initalized = true;

  final directoryPath = appSupportDir;

  final d = io.Directory(path.joinAll([directoryPath, "temporary"]));
  d.createSync();
  if (!temporary) {
    d.deleteSync(recursive: true);
    d.createSync();
  }
  final temporaryDbPath = d.path;

  final dimages = io.Directory(path.joinAll([directoryPath, "temp_images"]));
  dimages.createSync();
  if (!temporary) {
    dimages.deleteSync(recursive: true);
    dimages.createSync();
  }

  final temporaryImagesPath = dimages.path;

  final secondaryDir = path.join(directoryPath, "secondaryGrid");
  {
    io.Directory(secondaryDir).createSync();
  }

  final localTags = Isar.openSync(
    const [
      IsarTagSchema,
      IsarLocalTagsSchema,
      IsarLocalTagDictionarySchema,
      DirectoryTagSchema,
      IsarHottestTagSchema,
      IsarHottestTagDateSchema,
    ],
    directory: directoryPath,
    inspector: false,
    name: "localTags",
  );

  final main = Isar.openSync(
    mainSchemas,
    directory: directoryPath,
    inspector: false,
  );

  final blacklistedDirIsar = Isar.openSync(
    const [
      IsarBlacklistedDirectorySchema,
      IsarDirectoryMetadataSchema,
    ],
    directory: directoryPath,
    inspector: false,
    name: "androidBlacklistedDir",
  );

  if (main.isarFavoritePosts.countSync() != 0) {
    final favoritePostsIsar = Isar.openSync(
      const [IsarFavoritePostSchema],
      directory: directoryPath,
      inspector: false,
      name: "favoritePosts",
    );

    final ret = <IsarFavoritePost>[];
    final remove = <int>[];

    for (final e in _IsarCollectionReverseIterable(
      _IsarCollectionIterator(
        main.isarFavoritePosts,
        reversed: false,
        bufferLen: 100,
      ),
    )) {
      ret.add(e);
      remove.add(e.isarId!);

      if (ret.length == 100) {
        favoritePostsIsar.writeTxnSync(() {
          favoritePostsIsar.isarFavoritePosts.putAllByIdBooruSync(ret);
        });

        ret.clear();
      }
    }

    if (ret.isNotEmpty) {
      favoritePostsIsar.writeTxnSync(() {
        favoritePostsIsar.isarFavoritePosts.putAllByIdBooruSync(ret);
      });

      ret.clear();
    }

    main.writeTxnSync(() {
      main.isarFavoritePosts.deleteAllSync(remove);
    });

    await favoritePostsIsar.close();
  }

  Isar? thumbnailIsar;

  if (io.Platform.isAndroid) {
    thumbnailIsar = Isar.openSync(
      const [IsarThumbnailSchema],
      directory: directoryPath,
      inspector: false,
      name: "androidThumbnails",
    );
    thumbnailIsar.writeTxnSync(() {
      thumbnailIsar!.isarThumbnails
          .where()
          .differenceHashEqualTo(0)
          .or()
          .pathEqualTo("")
          .deleteAllSync();
    });
  }

  final favorites = FavoritePosts(directoryPath);

  _dbs = _Dbs._(
    directory: directoryPath,
    main: main,
    temporaryDbDir: temporaryDbPath,
    temporaryImagesDir: temporaryImagesPath,
    secondaryGridDbDir: secondaryDir,
    blacklisted: blacklistedDirIsar,
    thumbnail: thumbnailIsar,
    localTags: localTags,
    favorites: favorites,
  );

  IoServicesImplTable().favoritePosts.cache;
  await favorites.init();

  for (final e in _IsarCollectionReverseIterable(
    _IsarCollectionIterator(_Dbs.g.main.isarHiddenBooruPosts, reversed: false),
  )) {
    _dbs._hiddenBooruPostCachedValues[(e.postId, e.booru)] = e.thumbUrl;
  }

  final DownloadManager downloader;

  if (temporary) {
    final tempDownloaderPath =
        io.Directory(path.join(temporaryDir, "temporaryDownloads"))
          ..createSync()
          ..deleteSync(recursive: true)
          ..createSync();

    downloader = MemoryOnlyDownloadManager(tempDownloaderPath.path);
  } else {
    downloader = PersistentDownloadManager(db.downloads, temporaryDir);

    db.downloads.markInProgressAsFailed();

    for (final e in _IsarCollectionReverseIterable(
      _IsarCollectionIterator(
        _Dbs.g.main.isarDownloadFiles,
        reversed: false,
      ),
    )) {
      downloader.restoreFile(e);
    }

    await _removeTempContentsDownloads(temporaryDir);
  }

  return downloader;
}

Future<void> _removeTempContentsDownloads(String dir) async {
  try {
    final downld = io.Directory(path.join(dir, "downloads"));
    if (!downld.existsSync()) {
      return;
    }

    await for (final e in downld.list()) {
      e.deleteSync(recursive: true);
    }
  } catch (e, trace) {
    Logger.root.severe("deleting temp download directory", e, trace);
  }
}

abstract class IsolateIO<I, O> {
  void send(I i);

  Stream<O> get events;
}

class FavoritePosts
    implements IsolateIO<_FavoritePostData, _FavoritePostResult> {
  FavoritePosts(this._directory);

  final _loop = _FavoritePostsLoop();
  final String _directory;

  @override
  Stream<_FavoritePostResult> get events => _loop.events;

  Future<void> init() async {
    await _loop.init(_directory);
  }

  @override
  void send(_FavoritePostData i) {
    _loop.sendMessage(i);
  }

  void add(List<FavoritePost> posts) {
    _loop.sendMessage(AddPosts(posts));
  }

  void remove(List<(int, Booru)> posts) {
    _loop.sendMessage(RemovePosts(posts));
  }

  void clear() {
    _loop.sendMessage(const ClearPosts());
  }

  void dispose() {
    _loop.destroy();
  }
}

sealed class _FavoritePostData {
  const _FavoritePostData();
}

class AddPosts implements _FavoritePostData {
  const AddPosts(this.posts);

  final List<FavoritePost> posts;
}

class RemovePosts implements _FavoritePostData {
  const RemovePosts(this.posts);

  final List<(int id, Booru booru)> posts;
}

class ClearPosts implements _FavoritePostData {
  const ClearPosts();
}

@immutable
sealed class _FavoritePostResult {
  const _FavoritePostResult();
}

@immutable
class PostsAddedResult implements _FavoritePostResult {
  const PostsAddedResult(this.posts);

  final List<FavoritePost> posts;
}

class PostsRemovedResult implements _FavoritePostResult {
  const PostsRemovedResult(this.posts);

  final List<(int id, Booru booru)> posts;
}

class PostsClearResult implements _FavoritePostResult {
  const PostsClearResult();
}

class _FavoritePostsLoop extends IsolateLoop<String> {
  _FavoritePostsLoop() : super("Favorite Posts Isolate");

  final _resultEvents = StreamController<_FavoritePostResult>.broadcast();

  Stream<_FavoritePostResult> get events => _resultEvents.stream;

  @override
  Future<void> Function(({String data, SendPort port}) data) makeMain() => main;

  static Future<void> main(({String data, SendPort port}) data) async {
    Future<Isar> loadAndSend(String directory, SendPort port) async {
      final favoritePostDb = Isar.openSync(
        const [IsarFavoritePostSchema],
        directory: directory,
        inspector: false,
        name: "favoritePosts",
      );

      List<IsarFavoritePost> list = [];

      void send(_FavoritePostResult res) {
        port.send(res);
      }

      try {
        for (final e in _IsarCollectionReverseIterable(
          _IsarCollectionIterator(
            favoritePostDb.isarFavoritePosts,
            reversed: false,
            bufferLen: 100,
          ),
        )) {
          list.add(e);
          if (list.length == 100) {
            send(PostsAddedResult(List<IsarFavoritePost>.unmodifiable(list)));
            list = [];
          }
        }

        if (list.isNotEmpty) {
          send(PostsAddedResult(List<IsarFavoritePost>.unmodifiable(list)));
          list = const [];
        }
        send(const PostsAddedResult([]));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }

      return favoritePostDb;
    }

    final mgmt = IsolateManagement(data.port);
    await mgmt.init();

    final db = await mgmt.runCatch(() => loadAndSend(data.data, data.port));
    if (db == null) {
      mgmt.destroy();
      return;
    }

    void send(_FavoritePostResult res) {
      data.port.send(res);
    }

    void clearPosts() {
      db.writeTxnSync(() {
        db.isarFavoritePosts.clearSync();
      });

      send(const PostsClearResult());
    }

    void removePosts(List<(int id, Booru booru)> posts) {
      final (listA, listB) = posts.fold((<int>[], <Booru>[]), (lists, e) {
        lists.$1.add(e.$1);
        lists.$2.add(e.$2);

        return lists;
      });

      db.writeTxnSync(() {
        db.isarFavoritePosts.deleteAllByIdBooruSync(listA, listB);
      });

      send(PostsRemovedResult(posts));
    }

    void addPosts(List<FavoritePost> posts) {
      db.writeTxnSync(() {
        db.isarFavoritePosts.putAllByIdBooruSync(posts.cast());
      });

      send(PostsAddedResult(posts));
    }

    void messageEvents(dynamic e) {
      final message = e as _FavoritePostData;

      return switch (message) {
        AddPosts() => addPosts(message.posts),
        RemovePosts() => removePosts(message.posts),
        ClearPosts() => clearPosts(),
      };
    }

    await mgmt.listen(messageEvents);
  }

  @override
  void onEvent(dynamic e) {
    if (_resultEvents.isClosed) {
      return;
    }

    _resultEvents.add(e as _FavoritePostResult);
  }

  @override
  void destroy() {
    _resultEvents.close();
    super.destroy();
  }
}

abstract class IsolateLoop<Data> {
  IsolateLoop(String debugName) : _debugName = debugName;

  final _port = ReceivePort();
  late final Isolate _isolate;
  late final Stream<dynamic> _stream;
  late final StreamSubscription<dynamic> _events;
  late final SendPort _sendPort;

  final String _debugName;

  bool _isInit = false;
  bool _isDisposed = false;

  Future<void> init(Data data) {
    if (_isInit) {
      return Future.value();
    }
    _isInit = true;

    return _init(data);
  }

  Future<void> _init(Data data) async {
    _stream = _port.asBroadcastStream();

    final (port, isolate) = await (
      _stream.first,
      Isolate.spawn(
        makeMain(),
        (data: data, port: _port.sendPort),
        errorsAreFatal: false,
        debugName: _debugName,
      ),
    ).wait;

    _isolate = isolate;
    _sendPort = port as SendPort;
    _events = _stream.listen(onEvent);
  }

  Future<void> Function(({Data data, SendPort port}) data) makeMain();

  void sendMessage(dynamic e) {
    _sendPort.send(e);
  }

  void onEvent(dynamic e);

  void destroy() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    _events.cancel();
    _port.close();
    _isolate.kill();
  }
}

class IsolateManagement {
  IsolateManagement(this.port);

  final SendPort port;
  late final ReceivePort receivePort;

  bool _isInit = false;

  Future<void> init() {
    if (_isInit) {
      return Future.value();
    }
    _isInit = true;

    receivePort = ReceivePort();

    port.send(receivePort.sendPort);

    return Future.value();
  }

  Future<T?> runCatch<T>(Future<T> Function() f) {
    try {
      return f();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }

      return Future.value();
    }
  }

  Future<void> listen(void Function(dynamic) f) async {
    await for (final e in receivePort) {
      f(e);
    }
  }

  void destroy() {
    receivePort.close();
    Isolate.current.kill();
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../impl.dart";

bool _initalized = false;

const mainSchemas = [
  IsarVisitedPostSchema,
  IsarSettingsSchema,
  IsarFavoritePostSchema,
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

Future<void> _runIsolate((String, SendPort) value) async {
  final (directory, port) = value;

  try {
    final mainDb = Isar.openSync(
      mainSchemas,
      directory: directory,
      inspector: false,
    );

    List<IsarFavoritePost> list = [];

    try {
      for (final e in _IsarCollectionReverseIterable(
        _IsarCollectionIterator(
          mainDb.isarFavoritePosts,
          reversed: false,
          bufferLen: 100,
        ),
      )) {
        list.add(e);
        if (list.length == 100) {
          port.send(list);
          list = [];
        }
      }

      if (list.isNotEmpty) {
        port.send(list);
        list = const [];
      }
      port.send(const []);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    await mainDb.close();
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
}

Future<void> _favoritesLoop(
  ServicesImplTable db,
  String directoryPath,
) async {
  final port = ReceivePort();

  final isolate = await Isolate.spawn(
    _runIsolate,
    (directoryPath, port.sendPort),
    errorsAreFatal: false,
  );

  await for (final e in port) {
    final list = e as List<dynamic>;
    db.favoritePosts.backingStorage.addAll(list.cast<IsarFavoritePost>(), true);

    if (e.isEmpty) {
      db.favoritePosts.backingStorage.addAll(<IsarFavoritePost>[]);
      break;
    }
  }

  isolate.kill();
}

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

  Isar? thumbnailIsar;

  if (io.Platform.isAndroid) {
    thumbnailIsar = Isar.openSync(
      const [
        IsarThumbnailSchema,
        IsarPinnedThumbnailSchema,
      ],
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

  _dbs = _Dbs._(
    directory: directoryPath,
    main: main,
    temporaryDbDir: temporaryDbPath,
    temporaryImagesDir: temporaryImagesPath,
    secondaryGridDbDir: secondaryDir,
    blacklisted: blacklistedDirIsar,
    thumbnail: thumbnailIsar,
    localTags: localTags,
  );

  unawaited(_favoritesLoop(db, directoryPath));

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

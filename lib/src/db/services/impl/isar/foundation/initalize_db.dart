// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../impl.dart";

bool _initalized = false;

Future<DownloadManager> initalizeIsarDb(
  AppInstanceType appType,
  Services db,
  String appSupportDir,
  String temporaryDir,
) async {
  if (_initalized) {
    throw "already initalized";
  }

  _initalized = true;

  final temporary = appType != AppInstanceType.full;

  DbPaths.init(
    rootDirectory: appSupportDir,
    temporaryDir: path.joinAll([appSupportDir, "temporary"]),
    temporaryImagesDir: path.joinAll([appSupportDir, "temp_images"]),
    secondaryGridDir: path.join(appSupportDir, "secondaryGrid"),
  );

  final paths = DbPaths()..ensurePathsExist(temporary);

  Dbs.init(paths);

  if (Dbs().main.isarFavoritePosts.countSync() != 0) {
    await _moveFavoritePostsFromMain(
      rootDirectory: paths.rootDirectory,
      main: Dbs().main,
    );
  }

  // currently this is very fragile
  // favoritePosts.cache should be available before
  // the favorites Isolate is started
  IoServices().favoritePosts.cache;
  await Dbs().favorites.init();

  for (final e in IsarCollectionReverseIterable(
    IsarCollectionIterator(Dbs().main.isarHiddenBooruPosts, reversed: false),
  )) {
    Dbs().hiddenBooruPostCachedValues[(e.postId, e.booru)] = e.thumbUrl;
  }

  final DownloadManager downloader;

  if (temporary) {
    final tempDownloaderPath =
        io.Directory(path.join(temporaryDir, "temporaryDownloads"))
          ..createSync()
          ..deleteSync(recursive: true)
          ..createSync();

    downloader = MemoryOnlyDownloadManager(
      tempDownloaderPath.path,
      IoServices().galleryService.files,
      IoServices().settings,
    );
  } else {
    downloader = PersistentDownloadManager(
      IoServices().downloads,
      temporaryDir,
      IoServices().galleryService.files,
      IoServices().settings,
    );

    IoServices().downloads.markInProgressAsFailed();

    for (final e in IsarCollectionReverseIterable(
      IsarCollectionIterator(
        Dbs().main.isarDownloadFiles,
        reversed: false,
      ),
    )) {
      downloader.restoreFile(e);
    }

    await paths.removeTempContentsDownloads(temporaryDir);
  }

  return downloader;
}

Future<void> _moveFavoritePostsFromMain({
  required String rootDirectory,
  required Isar main,
}) async {
  final favoritePostsIsar = Isar.openSync(
    const [IsarFavoritePostSchema],
    directory: rootDirectory,
    inspector: false,
    name: "favoritePosts",
  );

  final ret = <IsarFavoritePost>[];
  final remove = <int>[];

  for (final e in IsarCollectionReverseIterable(
    IsarCollectionIterator(
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

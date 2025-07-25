// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../impl.dart";

bool _initalized = false;

Future<void> initalizeIsarDb(
  AppInstanceType appType,
  IoServices db,
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

  // currently this is very fragile
  // favoritePosts.cache should be available before
  // the favorites Isolate is started
  db.favoritePosts.cache;
  await Dbs().favorites.init();

  for (final e in IsarCollectionReverseIterable(
    IsarCollectionIterator(Dbs().main.isarHiddenBooruPosts, reversed: false),
  )) {
    Dbs().hiddenBooruPostCachedValues[(e.postId, e.booru)] = e.thumbUrl;
  }

  for (final e in IsarCollectionReverseIterable(
    IsarCollectionIterator(
      Dbs().blacklisted.isarDirectoryMetadatas,
      reversed: false,
    ),
  )) {
    db.directoryMetadata.cache.add(e, true);
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
    downloader = PersistentDownloadManager(
      db.downloads,
      temporaryDir,
      db.platformApi.files,
    );

    db.downloads.markInProgressAsFailed();

    for (final e in IsarCollectionReverseIterable(
      IsarCollectionIterator(Dbs().main.isarDownloadFiles, reversed: false),
    )) {
      downloader.restoreFile(e);
    }

    await paths.removeTempContentsDownloads(temporaryDir);
  }

  db.downloadManager = downloader;
}

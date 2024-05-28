// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../impl.dart";

const kPrimaryGridSchemas = [
  IsarGridTimeSchema,
  IsarGridStateSchema,
  IsarTagSchema,
  PostIsarSchema,
  IsarGridBooruPagingSchema,
];

late final _Dbs _dbs;

class _Dbs {
  _Dbs._({
    required this.localTags,
    required this.blacklisted,
    required this.directory,
    required this.main,
    required this.anime,
    required this.temporaryDbDir,
    required this.temporaryImagesDir,
    required this.thumbnail,
    required this.secondaryGridDbDir,
  });

  final _favoriteFilesCachedValues = <int, bool>{};
  // final _favoritePostsCachedValues = <(int, Booru), FavoritePostData>{};
  final _localTagsCachedValues = <String, String>{};
  final _hiddenBooruPostCachedValues = <(int, Booru), String>{};

  final _currentBooruDbs = <Booru, Isar>{};

  Isar booru(Booru booru) =>
      _currentBooruDbs.putIfAbsent(booru, () => _DbsOpen.primaryGrid(booru));

  final Isar main;
  final Isar anime;
  final Isar localTags;
  final Isar? thumbnail;
  final Isar blacklisted;

  final String directory;
  final String temporaryDbDir;
  final String temporaryImagesDir;
  final String secondaryGridDbDir;

  String get appStorageDir => directory;

  void clearTemporaryImages() {
    Directory(temporaryImagesDir)
      ..createSync()
      ..deleteSync(recursive: true)
      ..createSync();
  }

  static _Dbs get g => _dbs;
}

abstract class _DbsOpen {
  const _DbsOpen();

  static Isar primaryGrid(Booru booru) {
    final instance = Isar.getInstance(booru.string);
    if (instance != null) {
      return instance;
    }

    return Isar.openSync(
      kPrimaryGridSchemas,
      directory: _dbs.directory,
      inspector: false,
      name: booru.string,
    );
  }

  // static Isar secondaryGrid({bool temporary = true}) {
  //   return Isar.openSync(
  //     [PostIsarSchema, IsarGridBooruPagingSchema],
  //     directory: temporary ? _dbs.temporaryDbDir : _dbs.directory,
  //     inspector: false,
  //     name: _microsecSinceEpoch(),
  //   );
  // }

  static Isar secondaryGridName(String name, bool create) {
    if (!create &&
        !File(path.join(_dbs.secondaryGridDbDir, "$name.isar")).existsSync()) {
      throw "$name doesn't exist on disk";
    }

    return Isar.openSync(
      [PostIsarSchema, IsarGridBooruPagingSchema],
      directory: _dbs.secondaryGridDbDir,
      inspector: false,
      name: name,
    );
  }
  // static Isar androidGalleryDirectories([bool temporary = true]) =>
  //     Isar.openSync(
  //       kDirectoriesSchemas,
  //       directory: temporary ? _dbs.temporaryDbDir : _dbs.directory,
  //       inspector: false,
  //       name: temporary ? _microsecSinceEpoch() : "systemGalleryDirectories",
  //     );

  // static Isar androidGalleryFiles() => Isar.openSync(
  //       kFilesSchemas,
  //       directory: _dbs.temporaryDbDir,
  //       inspector: false,
  //       name: _microsecSinceEpoch(),
  //     );

  static String _microsecSinceEpoch() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}
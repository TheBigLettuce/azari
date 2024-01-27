// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'initalize_db.dart';

const kFilesSchemas = [SystemGalleryDirectoryFileSchema];
const kDirectoriesSchemas = [SystemGalleryDirectorySchema];
const kPrimaryGridSchemas = [
  GridStateSchema,
  TagSchema,
  PostSchema,
];

abstract class DbsOpen {
  static Isar primaryGrid(Booru booru) {
    final instance = Isar.getInstance(booru.string);
    if (instance != null) {
      return instance;
    }

    return Isar.openSync(kPrimaryGridSchemas,
        directory: _dbs.directory, inspector: false, name: booru.string);
  }

  static Isar secondaryGrid({bool temporary = true}) {
    return Isar.openSync([PostSchema],
        directory: temporary ? _dbs.temporaryDbDir : _dbs.directory,
        inspector: false,
        name: _microsecSinceEpoch());
  }

  static Isar secondaryGridName(String name) {
    return Isar.openSync([PostSchema],
        directory: _dbs.directory, inspector: false, name: name);
  }

  static Isar localTags() => Isar.openSync(
        [
          LocalTagsSchema,
          LocalTagDictionarySchema,
          DirectoryTagSchema,
          PinnedTagSchema,
        ],
        directory: _dbs.directory,
        inspector: false,
        name: "localTags",
      );

  static Isar androidGalleryDirectories({bool? temporary}) => Isar.openSync(
        kDirectoriesSchemas,
        directory: temporary == true ? _dbs.temporaryDbDir : _dbs.directory,
        inspector: false,
        name: temporary == true
            ? _microsecSinceEpoch()
            : "systemGalleryDirectories",
      );

  static Isar androidGalleryFiles() => Isar.openSync(
        kFilesSchemas,
        directory: _dbs.temporaryDbDir,
        inspector: false,
        name: _microsecSinceEpoch(),
      );

  static Isar temporarySchemas(List<CollectionSchema> schemas) => Isar.openSync(
        schemas,
        directory: _dbs.temporaryDbDir,
        inspector: false,
        name: _microsecSinceEpoch(),
      );

  static String _microsecSinceEpoch() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}

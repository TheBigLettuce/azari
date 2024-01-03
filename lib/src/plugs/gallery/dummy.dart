// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/gallery/blacklisted_directory.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory.dart';
import 'package:gallery/src/interfaces/filtering/filter_result.dart';
import 'package:gallery/src/interfaces/filtering/filtering_interface.dart';
import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'package:gallery/src/interfaces/filtering/sorting_mode.dart';
import 'package:gallery/src/interfaces/gallery/gallery_api_files.dart';
import 'package:gallery/src/interfaces/gallery/gallery_directories_extra.dart';
import 'package:gallery/src/plugs/gallery.dart';
import 'package:isar/isar.dart';

import '../../interfaces/gallery/gallery_api_directories.dart';

class DummyGallery implements GalleryPlug {
  @override
  Future<int> get version => Future.value(0);

  @override
  bool get temporary => true;

  @override
  void notify(String? target) {}

  @override
  GalleryAPIDirectories galleryApi(
      {bool? temporaryDb, bool setCurrentApi = true}) {
    return const _DummyDirectories();
  }
}

class _DummyDirectories implements GalleryAPIDirectories {
  @override
  void close() {}

  @override
  SystemGalleryDirectory directCell(int i) {
    throw UnimplementedError();
  }

  @override
  GalleryAPIFiles files(SystemGalleryDirectory d) {
    throw UnimplementedError();
  }

  @override
  GalleryDirectoriesExtra getExtra() {
    return const _DummyDirectoriesExtra();
  }

  @override
  Future<int> refresh() {
    return Future.value(0);
  }

  const _DummyDirectories();
}

class _DummyFilter implements FilterInterface<SystemGalleryDirectory> {
  @override
  FilterResult<SystemGalleryDirectory> filter(String s, FilteringMode mode) {
    return FilterResult((i) => throw UnimplementedError(), 0);
  }

  @override
  void resetFilter() {}

  @override
  void setSortingMode(SortingMode mode) {}

  const _DummyFilter();
}

class _DummyDirectoriesExtra implements GalleryDirectoriesExtra {
  @override
  void addBlacklisted(List<BlacklistedDirectory> bucketIds) {}

  @override
  Isar get db => throw UnimplementedError();

  @override
  FilterInterface<SystemGalleryDirectory> get filter => const _DummyFilter();

  @override
  GalleryAPIFiles favorites() {
    throw UnimplementedError();
  }

  @override
  GalleryAPIFiles trash() {
    throw UnimplementedError();
  }

  @override
  GalleryAPIFiles joinedDir(List<String> bucketIds) {
    throw UnimplementedError();
  }

  @override
  void setPassFilter(
      (Iterable<SystemGalleryDirectory>, dynamic) Function(
              Iterable<SystemGalleryDirectory> p1, dynamic p2, bool p3)?
          filter) {}

  @override
  void setRefreshGridCallback(void Function() callback) {}

  @override
  void setRefreshingStatusCallback(
      void Function(int i, bool inRefresh, bool empty) callback) {
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      callback(0, false, true);
    });
  }

  @override
  void setTemporarySet(void Function(int p1, bool p2) callback) {}

  const _DummyDirectoriesExtra();
}


// class _DummyFiles implements GalleryAPIFiles {
//   @override
//   void close() {}

//   @override
//   SystemGalleryDirectoryFile directCell(int i) {
//     throw UnimplementedError();
//   }

//   @override
//   GalleryFilesExtra getExtra() {
//     // TODO: implement getExtra
//     throw UnimplementedError();
//   }

//   @override
//   Future<int> refresh() {
//     return Future.value(0);
//   }

//   const _DummyFiles();
// }


// class _DirectoriesExtraDummy implements GalleryDirectoriesExtra {
//   @override
//   void addBlacklisted(List<BlacklistedDirectory> bucketIds) {}

//   @override
//   Isar get db => throw UnimplementedError();

//   @override
//   FilterInterface<SystemGalleryDirectory> get filter =>
//       throw UnimplementedError();

//   @override
//   GalleryAPIFiles favorites() {
//     throw UnimplementedError();
//   }

//   @override
//   GalleryAPIFiles trash() {
//     throw UnimplementedError();
//   }

//   @override
//   GalleryAPIFiles joinedDir(List<String> bucketIds) {
//     throw UnimplementedError();
//   }

//   @override
//   void setPassFilter(
//       (Iterable<SystemGalleryDirectory>, dynamic) Function(
//               Iterable<SystemGalleryDirectory> p1, dynamic p2, bool p3)?
//           filter) {}

//   @override
//   void setRefreshGridCallback(void Function() callback) {}

//   @override
//   void setRefreshingStatusCallback(
//       void Function(int i, bool inRefresh, bool empty) callback) {}

//   @override
//   void setTemporarySet(void Function(int p1, bool p2) callback) {}

//   const _
// }

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";
import "package:gallery/src/plugs/gallery.dart";

class DummyGallery implements GalleryPlug {
  @override
  Future<int> get version => Future.value(0);

  @override
  bool get temporary => true;

  @override
  void notify(String? target) {}

  @override
  GalleryAPIDirectories galleryApi(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    bool? temporaryDb,
    bool setCurrentApi = true,
  }) {
    return const _DummyDirectories();
  }
}

class _DummyDirectories implements GalleryAPIDirectories {
  const _DummyDirectories();
  @override
  void close() {}

  @override
  GalleryAPIFiles? get bindFiles => null;

  @override
  GalleryAPIFiles files(GalleryDirectory d, GalleryFilesPageType type) {
    throw UnimplementedError();
  }

  @override
  GalleryAPIFiles joinedFiles(List<String> bucketIds) {
    throw UnimplementedError();
  }

  @override
  ResourceSource<GalleryDirectory> get source => throw UnimplementedError();
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

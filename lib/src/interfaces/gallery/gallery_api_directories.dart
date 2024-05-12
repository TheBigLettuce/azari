// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";
import "package:gallery/src/plugs/gallery.dart";

enum GalleryFilesPageType {
  normal,
  trash,
  favorites;

  bool isFavorites() => this == favorites;
  bool isTrash() => this == trash;
}

abstract class GalleryAPIDirectories {
  ResourceSource<GalleryDirectory> get source;

  GalleryAPIFiles? get bindFiles;

  GalleryAPIFiles files(GalleryDirectory d, GalleryFilesPageType type);
  GalleryAPIFiles joinedFiles(List<String> bucketIds);

  void close();
}

// abstract class GalleryDirectoriesExtra {
//   bool get currentlyHostingFiles;

//   GalleryAPIFiles joinedDir(List<String> bucketIds);
//   GalleryAPIFiles trash();
//   GalleryAPIFiles favorites();

//   void setRefreshGridCallback(void Function() callback);
//   void setTemporarySet(void Function(int, bool) callback);
//   void setRefreshingStatusCallback(
//     void Function(int i, bool inRefresh, bool empty) callback,
//   );

//   void setPassFilter(
//     (Iterable<GalleryDirectory>, dynamic) Function(
//       Iterable<GalleryDirectory>,
//       dynamic,
//       bool,
//     )? filter,
//   );
// }

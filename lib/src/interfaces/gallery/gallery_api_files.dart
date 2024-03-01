// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart';
import 'package:gallery/src/interfaces/filtering/filtering_interface.dart';
import 'package:isar/isar.dart';

abstract class GalleryAPIFiles {
  SystemGalleryDirectoryFile directCell(int i, [bool bypassFilter = false]);

  Future<int> refresh();
  GalleryFilesExtra getExtra();

  void close();
}

abstract class GalleryFilesExtra {
  FilterInterface<SystemGalleryDirectoryFile> get filter;
  Isar get db;

  bool get supportsDirectRefresh;
  bool get isTrash;
  bool get isFavorites;

  void setRefreshGridCallback(void Function() callback);
  Future<void> loadNextThumbnails(void Function() callback);
  void setRefreshingStatusCallback(
      void Function(int i, bool inRefresh, bool empty) callback);
  void setPassFilter(
      (Iterable<SystemGalleryDirectoryFile>, dynamic) Function(
              Iterable<SystemGalleryDirectoryFile> cells,
              dynamic data,
              bool end)
          f);
}

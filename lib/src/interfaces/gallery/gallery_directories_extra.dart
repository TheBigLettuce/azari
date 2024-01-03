// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/schemas/gallery/blacklisted_directory.dart';
import 'package:isar/isar.dart';

import '../../db/schemas/gallery/system_gallery_directory.dart';
import '../filtering/filtering_interface.dart';
import 'gallery_api_files.dart';

abstract class GalleryDirectoriesExtra {
  FilterInterface<SystemGalleryDirectory> get filter;
  Isar get db;

  GalleryAPIFiles joinedDir(List<String> bucketIds);
  GalleryAPIFiles trash();
  GalleryAPIFiles favorites();

  void addBlacklisted(List<BlacklistedDirectory> bucketIds);

  void setRefreshGridCallback(void Function() callback);
  void setTemporarySet(void Function(int, bool) callback);
  void setRefreshingStatusCallback(
      void Function(int i, bool inRefresh, bool empty) callback);

  void setPassFilter(
      (Iterable<SystemGalleryDirectory>, dynamic) Function(
              Iterable<SystemGalleryDirectory>, dynamic, bool)?
          filter);
}

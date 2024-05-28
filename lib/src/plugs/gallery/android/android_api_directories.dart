// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery/android/api.g.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/network_status.dart";
import "package:gallery/src/plugs/platform_functions.dart";

part "android_api_files.dart";
part "android_gallery.dart";
part "gallery_impl.dart";

class _AndroidGallery implements GalleryAPIDirectories {
  _AndroidGallery(
    this.blacklistedDirectory,
    this.directoryTag, {
    required this.temporary,
  });

  final BlacklistedDirectoryService blacklistedDirectory;
  final DirectoryTagService directoryTag;

  final bool temporary;
  final time = DateTime.now();

  bool isThumbsLoading = false;

  @override
  _AndroidGalleryFiles? bindFiles;

  @override
  void close() {
    source.destroy();
    bindFiles = null;
    if (temporary == false) {
      _global!._currentApi = null;
    } else if (temporary) {
      // _global!._temporaryApis.removeWhere((element) => element.time == time);
    }
  }

  @override
  GalleryAPIFiles files(
    GalleryDirectory d,
    GalleryFilesPageType type,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
  ) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    return bindFiles = _AndroidGalleryFiles(
      source: _AndroidFileSourceJoined([d.bucketId]),
      bucketId: d.bucketId,
      target: d.name,
      type: type,
      parent: this,
      directoryMetadata: directoryMetadata,
      directoryTag: directoryTag,
    );
  }

  @override
  GalleryAPIFiles joinedFiles(
    List<String> bucketIds,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
  ) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    return bindFiles = _JoinedDirectories(
      source: _AndroidFileSourceJoined(bucketIds),
      directories: bucketIds,
      parent: this,
      directoryMetadata: directoryMetadata,
      directoryTag: directoryTag,
    );
  }

  @override
  final _AndroidSource source = _AndroidSource();
}

class _AndroidSource implements ResourceSource<int, GalleryDirectory> {
  _AndroidSource();

  @override
  int get count => backingStorage.count;

  @override
  bool get hasNext => false;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  final SourceStorage<int, GalleryDirectory> backingStorage = ListStorage();

  @override
  Future<int> clearRefresh() {
    if (progress.inRefreshing) {
      return Future.value(count);
    }
    progress.inRefreshing = true;

    backingStorage.clear();
    GalleryManagementApi.current().refreshGallery();

    return Future.value(count);
  }

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    backingStorage.destroy();
    progress.close();
  }
}

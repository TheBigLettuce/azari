// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/platform/platform_api.g.dart" as platform;
import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/resource_source/source_storage.dart";
import "package:azari/src/logic/trash_cell.dart";
import "package:azari/src/services/services.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";

part "android_api_directories.dart";
part "android_api_files.dart";

extension DirectoryFileToAndroidFile on platform.DirectoryFile {
  static final _regxp = RegExp("[(][0-9].*[)][.][a-zA-Z0-9].*");

  File toAndroidFile(Map<String, void> tags) {
    return File(
      tags: tags,
      id: id,
      bucketId: bucketId,
      name: name,
      lastModified: lastModified,
      originalUri: originalUri,
      height: height,
      width: width,
      size: size,
      isVideo: isVideo,
      isGif: isGif,
      isDuplicate: _regxp.hasMatch(name),
      res: ParsedFilenameResult.simple(name),
    );
  }
}

class AndroidGalleryApi implements GalleryService {
  const AndroidGalleryApi();

  static const appContext =
      MethodChannel("com.github.thebiglettuce.azari.app_context");

  static const activityContext =
      MethodChannel("com.github.thebiglettuce.azari.activity_context");

  @override
  Directories open() => _AndroidGallery();

  @override
  GalleryTrash get trash => const _TrashImpl();

  // @override
  // ThumbsApi get thumbs => const AndroidCachedThumbs();

  // @override
  // FilesApi get files => const AndroidFilesManagement();

  // @override
  // Search get search => AndroidSearch(localTagsService);
}

class _TrashImpl implements GalleryTrash {
  const _TrashImpl();

  @override
  Future<Directory?> get thumb =>
      AndroidGalleryApi.appContext.invokeMethod("trashThumbId").then(
            (e) => e == null
                ? null
                : Directory(
                    bucketId: "trash",
                    name: "Trash", // TODO: localize this somehow
                    tag: "",
                    volumeName: "",
                    relativeLoc: "",
                    lastModified: 0,
                    thumbFileId: e as int,
                  ),
          );

  @override
  void addAll(List<String> uris) =>
      AndroidGalleryApi.activityContext.invokeMethod("addToTrash", uris);

  @override
  void removeAll(List<String> uris) =>
      AndroidGalleryApi.activityContext.invokeMethod("removeFromTrash", uris);

  @override
  void empty() => AndroidGalleryApi.activityContext.invokeMethod("emptyTrash");
}

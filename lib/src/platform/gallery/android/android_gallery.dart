// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io" as io;

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/platform/generated/platform_api.g.dart" as platform;
import "package:azari/src/platform/network_status.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

part "android_api_directories.dart";
part "android_api_files.dart";
part "gallery_impl.dart";
part "management.dart";

extension DirectoryFileToAndroidFile on platform.DirectoryFile {
  static final _regxp = RegExp("[(][0-9].*[)][.][a-zA-Z0-9].*");

  File toAndroidFile(Map<String, void> tags) {
    return AndroidGalleryFile(
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

class AndroidGalleryApi implements GalleryApi {
  const AndroidGalleryApi();

  static const appContext =
      MethodChannel("com.github.thebiglettuce.azari.app_context");

  static const activityContext =
      MethodChannel("com.github.thebiglettuce.azari.activity_context");

  @override
  Future<int> get version => platform.GalleryHostApi().mediaVersion();

  @override
  Directories openDirectory(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    required AppLocalizations l10n,
  }) {
    final api = _AndroidGallery(
      blacklistedDirectory,
      directoryTag,
      localizations: l10n,
    );

    return _GalleryImpl()._currentApi = api;
  }

  @override
  void notify(String? target) {
    _GalleryImpl().notify(target);
  }

  @override
  Events get events => const _Events();

  @override
  GalleryTrash get trash => const AndroidGalleryTrash();

  @override
  CachedThumbs get thumbs => const AndroidCachedThumbs();

  @override
  FilesManagement get files => const AndroidFilesManagement();

  @override
  Search get search => const AndroidSearch();

  @override
  Future<({String path, String formattedPath})?> chooseDirectory(
    AppLocalizations _, {
    bool temporary = false,
  }) async {
    return activityContext.invokeMethod("chooseDirectory", temporary).then(
          (value) => (
            formattedPath: (value as Map)["pathDisplay"] as String,
            path: value["path"] as String,
          ),
        );
  }
}

void initalizeAndroidGallery() {
  _GalleryImpl();
}

class AndroidSearch implements Search {
  const AndroidSearch();

  @override
  Future<List<File>> filesById(List<int> ids) {
    final localTags = LocalTagsService.db();

    return platform.GalleryHostApi().getPicturesOnlyDirectly(ids).then(
          (e) => e
              .map(
                (e) => e.toAndroidFile(
                  localTags.get(e.name).fold({}, (map, e) {
                    map[e] = null;
                    return map;
                  }),
                ),
              )
              .toList(),
        );
  }

  @override
  Future<List<File>> filesByName(String name, int limit) {
    final localTags = LocalTagsService.db();

    return platform.GalleryHostApi().latestFilesByName(name, limit).then(
          (e) => e
              .map(
                (e) => e.toAndroidFile(
                  localTags.get(e.name).fold({}, (map, e) {
                    map[e] = null;
                    return map;
                  }),
                ),
              )
              .toList(),
        );
  }
}

class _Events implements Events {
  const _Events();

  static final StreamController<void> _tapDown = StreamController.broadcast();

  static final StreamController<platform.GalleryPageChangeEvent> _pageChange =
      StreamController.broadcast();

  @override
  Stream<platform.GalleryPageChangeEvent>? get pageChange => _pageChange.stream;

  @override
  Stream<void>? get tapDown => _tapDown.stream;
}

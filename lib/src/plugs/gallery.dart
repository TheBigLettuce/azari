// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:developer";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/main.dart";
import "package:gallery/restart_widget.dart";
import "package:gallery/src/db/gallery_thumbnail_provider.dart";
import "package:gallery/src/db/services/post_tags.dart";
import "package:gallery/src/db/services/resource_source/resource_source.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/logging/logging.dart";
import "package:gallery/src/net/booru/booru_api.dart";
import "package:gallery/src/net/booru/post.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/plugs/gallery/dummy_.dart"
    if (dart.library.io) "package:gallery/src/plugs/gallery/io.dart"
    if (dart.library.html) "package:gallery/src/plugs/gallery/web.dart";
import "package:gallery/src/plugs/gallery_file_functions.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/empty_widget.dart";
import "package:gallery/src/widgets/glue_provider.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/label_switcher_widget.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";
import "package:gallery/src/widgets/search/search_text_field.dart";
import "package:gallery/src/widgets/tags_list_widget.dart";
import "package:isar/isar.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";
import "package:url_launcher/url_launcher.dart";

part "gallery_directory.dart";
part "gallery_file.dart";

GalleryPlug chooseGalleryPlug() => getApi();

void initalizeGalleryPlug(bool temporary) => initApi(temporary);

abstract interface class GalleryPlug with GalleryObjFactoryMixin {
  GalleryAPIDirectories galleryApi(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    required AppLocalizations l10n,
  });

  void notify(String? target);
  bool get temporary;
  Future<int> get version;
}

abstract class GalleryAPIDirectories {
  ResourceSource<int, GalleryDirectory> get source;
  TrashCell get trashCell;

  GalleryAPIFiles? get bindFiles;

  GalleryAPIFiles files(
    String bucketId,
    String name,
    GalleryFilesPageType type,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  );

  GalleryAPIFiles joinedFiles(
    List<String> bucketIds,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  );

  void close();
}

abstract class GalleryAPIFiles {
  DirectoryTagService get directoryTag;
  DirectoryMetadataService get directoryMetadata;
  FavoriteFileService get favoriteFile;
  LocalTagsService get localTags;

  SortingResourceSource<int, GalleryFile> get source;

  GalleryFilesPageType get type;

  GalleryAPIDirectories get parent;

  List<String> get bucketIds;

  void close();
}

enum GalleryFilesPageType {
  normal,
  trash,
  favorites;

  bool isFavorites() => this == favorites;
  bool isTrash() => this == trash;
}

mixin GalleryObjFactoryMixin {
  GalleryDirectory makeGalleryDirectory({
    required int thumbFileId,
    required String bucketId,
    required String name,
    required String relativeLoc,
    required String volumeName,
    required int lastModified,
    required String tag,
  });

  GalleryFile makeGalleryFile({
    required String tagsFlat,
    required int id,
    required String bucketId,
    required String name,
    required int lastModified,
    required String originalUri,
    required int height,
    required int width,
    required int size,
    required bool isVideo,
    required bool isGif,
    required bool isDuplicate,
  });
}

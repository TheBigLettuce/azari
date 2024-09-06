// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/app_info.dart";
import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/gallery_thumbnail_provider.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/post_functions.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/more/settings/radio_dialog.dart";
import "package:azari/src/plugs/gallery/io.dart"
    if (dart.library.html) "package:azari/src/plugs/gallery/web.dart";
import "package:azari/src/plugs/gallery_file_functions.dart";
import "package:azari/src/plugs/gallery_management_api.dart";
import "package:azari/src/plugs/generated/platform_api.g.dart";
import "package:azari/src/plugs/notifications.dart";
import "package:azari/src/plugs/platform_functions.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:azari/src/widgets/load_tags.dart";
import "package:azari/src/widgets/menu_wrapper.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";
import "package:url_launcher/url_launcher.dart";

part "gallery_directory.dart";
part "gallery_file.dart";

GalleryPlug chooseGalleryPlug() => getApi();

void initGalleryPlug(bool temporary) => initApi(temporary);

abstract interface class GalleryPlug with GalleryObjFactoryMixin {
  GalleryAPIDirectories galleryApi(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    required AppLocalizations l10n,
  });

  void notify(String? target);
  bool get temporary;
  Future<int> get version;

  Stream<void>? get galleryTapDownEvents;
}

abstract class GalleryAPIDirectories {
  ResourceSource<int, GalleryDirectory> get source;
  TrashCell get trashCell;

  GalleryAPIFiles? get bindFiles;

  GalleryAPIFiles files(
    GalleryDirectory directory,
    String name,
    GalleryFilesPageType type,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  );

  GalleryAPIFiles joinedFiles(
    List<GalleryDirectory> directories,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoriteFileService favoriteFile,
    LocalTagsService localTags,
  );

  void close();
}

class PlainGalleryDirectory extends GalleryDirectoryBase with GalleryDirectory {
  const PlainGalleryDirectory({
    required super.bucketId,
    required super.name,
    required super.tag,
    required super.volumeName,
    required super.relativeLoc,
    required super.lastModified,
    required super.thumbFileId,
  });
}

class _FakeGalleryAPIFiles implements GalleryAPIFiles {
  _FakeGalleryAPIFiles(
    Future<List<GalleryFile>> Function() clearRefresh,
    this.directoryMetadata,
    this.directoryTag,
    this.favoriteFile,
    this.localTags,
    this.parent,
  ) : source = _GenericListSource(clearRefresh);

  @override
  List<GalleryDirectory> get directories => const [
        PlainGalleryDirectory(
          bucketId: "latest",
          name: "latest",
          tag: "",
          volumeName: "",
          relativeLoc: "",
          lastModified: 0,
          thumbFileId: 0,
        ),
      ];

  @override
  final DirectoryMetadataService directoryMetadata;

  @override
  final DirectoryTagService directoryTag;

  @override
  final FavoriteFileService favoriteFile;

  @override
  final LocalTagsService localTags;

  @override
  final GalleryAPIDirectories parent;

  @override
  final SortingResourceSource<int, GalleryFile> source;

  @override
  GalleryFilesPageType get type => GalleryFilesPageType.normal;

  @override
  void close() {
    source.destroy();
  }

  @override
  FilesSourceTags get sourceTags => const _FakeSourceTags();
}

class _FakeSourceTags implements FilesSourceTags {
  const _FakeSourceTags();

  @override
  List<String> get current => const [];

  @override
  StreamSubscription<List<String>> watch(void Function(List<String> p1) f) =>
      const Stream<List<String>>.empty().listen(f);
}

class _GenericListSource extends GenericListSource<GalleryFile>
    implements SortingResourceSource<int, GalleryFile> {
  _GenericListSource(super.clearRefresh);

  @override
  Future<int> clearRefreshSilent() => clearRefresh();

  @override
  SortingMode get sortingMode => SortingMode.none;

  @override
  set sortingMode(SortingMode s) {}
}

abstract class GalleryAPIFiles {
  factory GalleryAPIFiles.fake(
    DbConn db, {
    required Future<List<GalleryFile>> Function() clearRefresh,
    required GalleryAPIDirectories parent,
  }) {
    return _FakeGalleryAPIFiles(
      clearRefresh,
      db.directoryMetadata,
      db.directoryTags,
      db.favoriteFiles,
      db.localTags,
      parent,
    );
  }

  DirectoryTagService get directoryTag;
  DirectoryMetadataService get directoryMetadata;
  FavoriteFileService get favoriteFile;
  LocalTagsService get localTags;

  SortingResourceSource<int, GalleryFile> get source;
  FilesSourceTags get sourceTags;

  GalleryFilesPageType get type;

  GalleryAPIDirectories get parent;

  List<GalleryDirectory> get directories;

  void close();
}

abstract class FilesSourceTags {
  List<String> get current;
  StreamSubscription<List<String>> watch(void Function(List<String>) f);
}

class MapFilesSourceTags implements FilesSourceTags {
  MapFilesSourceTags();

  final Map<String, int> _map = {};
  List<String>? _sorted;
  final _events = StreamController<List<String>>.broadcast();

  void addAll(List<String> tags) {
    for (final tag in tags) {
      final v = _map.putIfAbsent(tag, () => 0);
      _map[tag] = v + 1;
    }
  }

  void notify() {
    _events.add(_sortMap());
  }

  void clear() {
    _sorted = null;
    _map.clear();
  }

  void dispose() {
    _events.close();
  }

  @override
  List<String> get current => _sortMap();

  List<String> _sortMap() {
    if (_sorted != null) {
      return _sorted!;
    }

    if (_map.length <= 15) {
      final l = _map.entries.toList()
        ..sort((e1, e2) {
          return e2.value.compareTo(e1.value);
        });

      return l.map((e) => e.key).toList();
    }

    final entries = _map.entries
        .where(
          (e) => e.value != (1 + (_map.length * 0.02)),
        )
        .take(1000)
        .toList();

    entries.sort((e1, e2) => e2.value.compareTo(e1.value));

    return _sorted = entries.take(15).map((e) => e.key).toList();
  }

  @override
  StreamSubscription<List<String>> watch(void Function(List<String> p1) f) =>
      _events.stream.listen(f);
}

enum GalleryFilesPageType {
  normal,
  trash,
  favorites;

  bool isFavorites() => this == favorites;
  bool isTrash() => this == trash;

  static bool filterAuthBlur(
    Map<String, DirectoryMetadata> m,
    DirectoryFile? dir,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
  ) {
    final segment = GalleryDirectories.segmentCell(
      dir!.bucketName,
      dir.bucketId,
      directoryTag,
    );

    DirectoryMetadata? data = m[segment];
    if (data == null) {
      final d = directoryMetadata.get(segment);
      if (d == null) {
        return true;
      }

      data = d;
      m[segment] = d;
    }

    return !data.requireAuth && !data.blur;
  }
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
    required Map<String, void> tags,
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

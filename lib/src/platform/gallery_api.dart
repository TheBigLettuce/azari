// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/app_info.dart";
import "package:azari/init_main/restart_widget.dart";
import "package:azari/l10n/generated/app_localizations.dart";
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
import "package:azari/src/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/pages/home.dart";
import "package:azari/src/pages/more/settings/radio_dialog.dart";
import "package:azari/src/platform/gallery/io.dart"
    if (dart.library.html) "package:azari/src/platform/gallery/web.dart";
import "package:azari/src/platform/gallery_file_functions.dart";
import "package:azari/src/platform/generated/platform_api.g.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:azari/src/widgets/load_tags.dart";
import "package:azari/src/widgets/menu_wrapper.dart";
import "package:azari/src/widgets/translation_notes.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";
import "package:url_launcher/url_launcher.dart";

export "package:azari/src/platform/generated/platform_api.g.dart"
    show GalleryPageChangeEvent;

part "gallery_directory.dart";
part "gallery_file.dart";

void initGalleryPlug() => initApi();

abstract interface class GalleryApi {
  factory GalleryApi() {
    if (_api != null) {
      return _api!;
    }

    return _api = getApi();
  }

  static GalleryApi? _api;

  Directories openDirectory(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    required AppLocalizations l10n,
  });

  GalleryTrash get trash;
  CachedThumbs get thumbs;
  FilesManagement get files;
  Search get search;

  Future<({String formattedPath, String path})?> chooseDirectory(
    AppLocalizations l10n, {
    bool temporary = false,
  });

  void notify(String? target);
  Future<int> get version;

  Events get events;
}

abstract class Search {
  const factory Search.dummy() = _DummySearch;

  Future<List<File>> filesByName(String name, int limit);
  Future<List<File>> filesById(List<int> ids);
}

abstract class Events {
  const factory Events.none() = _NoEvents;

  Stream<void>? get tapDown;
  Stream<GalleryPageChangeEvent>? get pageChange;
}

class _DummySearch implements Search {
  const _DummySearch();

  @override
  Future<List<File>> filesById(List<int> ids) => Future.value(const []);

  @override
  Future<List<File>> filesByName(String name, int limit) =>
      Future.value(const []);
}

class _NoEvents implements Events {
  const _NoEvents();

  @override
  Stream<GalleryPageChangeEvent>? get pageChange => null;

  @override
  Stream<void>? get tapDown => null;
}

abstract class Directories {
  ResourceSource<int, Directory> get source;
  TrashCell get trashCell;

  Files? get bindFiles;

  Files files(
    Directory directory,
    GalleryFilesPageType type,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoritePostSourceService favoritePosts,
    LocalTagsService localTags, {
    required String bucketId,
    required String name,
  });

  Files joinedFiles(
    List<Directory> directories,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoritePostSourceService favoritePosts,
    LocalTagsService localTags,
  );

  void close();
}

class PlainDirectory extends Directory {
  const PlainDirectory({
    required super.bucketId,
    required super.name,
    required super.tag,
    required super.volumeName,
    required super.relativeLoc,
    required super.lastModified,
    required super.thumbFileId,
  });
}

class _FakeFiles implements Files {
  _FakeFiles(
    Future<List<File>> Function() clearRefresh,
    this.directoryMetadata,
    this.directoryTag,
    this.favoritePosts,
    this.localTags,
    this.parent,
  ) : source = _GenericListSource(clearRefresh);

  @override
  List<Directory> get directories => const [
        PlainDirectory(
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
  final FavoritePostSourceService favoritePosts;

  @override
  final LocalTagsService localTags;

  @override
  final Directories parent;

  @override
  final SortingResourceSource<int, File> source;

  @override
  GalleryFilesPageType get type => GalleryFilesPageType.normal;

  @override
  void close() {
    source.destroy();
  }

  @override
  FilesSourceTags get sourceTags => const _FakeSourceTags();

  @override
  String get bucketId => "latest";
}

class _FakeSourceTags implements FilesSourceTags {
  const _FakeSourceTags();

  @override
  List<String> get current => const [];

  @override
  StreamSubscription<List<String>> watch(void Function(List<String> p1) f) =>
      const Stream<List<String>>.empty().listen(f);
}

class _GenericListSource extends GenericListSource<File>
    implements SortingResourceSource<int, File> {
  _GenericListSource(super.clearRefresh);

  @override
  Future<int> clearRefreshSilent() => clearRefresh();

  @override
  SortingMode get sortingMode => SortingMode.none;

  @override
  set sortingMode(SortingMode s) {}
}

abstract class Files {
  factory Files.fake(
    DbConn db, {
    required Future<List<File>> Function() clearRefresh,
    required Directories parent,
  }) {
    return _FakeFiles(
      clearRefresh,
      db.directoryMetadata,
      db.directoryTags,
      db.favoritePosts,
      db.localTags,
      parent,
    );
  }

  DirectoryTagService get directoryTag;
  DirectoryMetadataService get directoryMetadata;
  FavoritePostSourceService get favoritePosts;
  LocalTagsService get localTags;

  SortingResourceSource<int, File> get source;
  FilesSourceTags get sourceTags;

  GalleryFilesPageType get type;

  Directories get parent;

  List<Directory> get directories;
  String get bucketId;

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
    File? dir,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
  ) {
    final segment = DirectoriesPage.segmentCell(
      dir!.name,
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

abstract interface class FilesManagement {
  const factory FilesManagement.dummy() = _DummyFilesManagement;

  Future<void> rename(String uri, String newName, [bool notify = true]);

  Future<bool> exists(String filePath);

  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  });

  Future<void> copyMoveInternal({
    required String relativePath,
    required String volume,
    required String dirName,
    required List<String> internalPaths,
  });

  Future<void> copyMove(
    String chosen,
    String chosenVolumeName,
    List<File> selected, {
    required bool move,
    required bool newDir,
  });

  void deleteAll(List<File> selected);
}

abstract interface class CachedThumbs {
  const factory CachedThumbs.dummy() = _DummyCachedThumbs;

  Future<int> size([bool fromPinned = false]);

  Future<ThumbId> get(int id);

  void clear([bool fromPinned = false]);

  void removeAll(List<int> id, [bool fromPinned = false]);

  Future<ThumbId> saveFromNetwork(String url, int id);
}

abstract interface class GalleryTrash {
  const factory GalleryTrash.dummy() = _DummyGalleryTrash;

  Future<Directory?> get thumb;

  void addAll(List<String> uris);

  void empty();

  void removeAll(List<String> uris);
}

class _DummyGalleryTrash implements GalleryTrash {
  const _DummyGalleryTrash();

  @override
  void addAll(List<String> uris) {}

  @override
  void empty() {}

  @override
  void removeAll(List<String> uris) {}

  @override
  Future<Directory?> get thumb => Future.value();
}

class _DummyFilesManagement implements FilesManagement {
  const _DummyFilesManagement();

  @override
  void deleteAll(List<File> selected) {}

  @override
  Future<bool> exists(String filePath) => Future.value(false);

  @override
  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  }) =>
      Future.value();

  @override
  Future<void> rename(String uri, String newName, [bool notify = true]) =>
      Future.value();

  @override
  Future<void> copyMove(
    String chosen,
    String chosenVolumeName,
    List<File> selected, {
    required bool move,
    required bool newDir,
  }) =>
      Future.value();

  @override
  Future<void> copyMoveInternal({
    required String relativePath,
    required String volume,
    required String dirName,
    required List<String> internalPaths,
  }) =>
      Future.value();
}

@immutable
class ThumbId {
  const ThumbId({
    required this.id,
    required this.path,
    required this.differenceHash,
  });

  final int id;
  final int differenceHash;

  final String path;
}

class _DummyCachedThumbs implements CachedThumbs {
  const _DummyCachedThumbs();

  @override
  void clear([bool fromPinned = false]) {}

  @override
  Future<ThumbId> get(int id) => throw UnimplementedError();

  @override
  void removeAll(List<int> id, [bool fromPinned = false]) {}

  @override
  Future<ThumbId> saveFromNetwork(String url, int id) {
    throw UnimplementedError();
  }

  @override
  Future<int> size([bool fromPinned = false]) => Future.value(0);
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class GalleryService implements ServiceMarker {
  Directories open({
    required SettingsService settingsService,
    required BlacklistedDirectoryService? blacklistedDirectory,
    required DirectoryTagService? directoryTags,
    required GalleryTrash? galleryTrash,
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

abstract class Directory
    implements DirectoryBase, DirectoryImpl, Pressable<Directory> {
  const factory Directory({
    required int lastModified,
    required int thumbFileId,
    required String bucketId,
    required String name,
    required String tag,
    required String volumeName,
    required String relativeLoc,
  }) = $Directory;
}

abstract class DirectoryBase {
  const DirectoryBase();

  int get thumbFileId;

  int get lastModified;

  String get bucketId;

  String get name;

  String get relativeLoc;
  String get volumeName;

  String get tag;
}

abstract class File implements FileBase, FileImpl, Pressable<File> {
  const factory File({
    required Map<String, void> tags,
    required int id,
    required String bucketId,
    required String name,
    required bool isVideo,
    required bool isGif,
    required int size,
    required int height,
    required bool isDuplicate,
    required int width,
    required int lastModified,
    required String originalUri,
    required (int, Booru)? res,
  }) = $File;
}

abstract class FileBase {
  const FileBase();

  int get id;
  String get bucketId;

  String get name;

  int get lastModified;
  String get originalUri;

  int get height;
  int get width;

  int get size;

  bool get isVideo;
  bool get isGif;
  bool get isDuplicate;

  Map<String, void> get tags;

  (int, Booru)? get res;
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
  TrashCell? get trashCell;

  Files? get bindFiles;

  Files files(
    Directory directory,
    GalleryFilesPageType type,
    DirectoryTagService? directoryTag,
    DirectoryMetadataService? directoryMetadata,
    FavoritePostSourceService? favoritePosts,
    LocalTagsService? localTags, {
    required String bucketId,
    required String name,
  });

  Files joinedFiles(
    List<Directory> directories,
    DirectoryTagService? directoryTag,
    DirectoryMetadataService? directoryMetadata,
    FavoritePostSourceService? favoritePosts,
    LocalTagsService? localTags,
  );

  void close();
}

class _FakeFiles implements Files {
  _FakeFiles(
    Future<List<File>> Function() clearRefresh,
    this.directoryMetadata,
    this.directoryTags,
    this.favoritePosts,
    this.localTags,
    this.parent,
  ) : source = _GenericListSource(clearRefresh);

  @override
  List<Directory> get directories => const [
        Directory(
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
  final DirectoryMetadataService? directoryMetadata;

  @override
  final DirectoryTagService? directoryTags;

  @override
  final FavoritePostSourceService? favoritePosts;

  @override
  final LocalTagsService? localTags;

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
  factory Files.fake({
    required Future<List<File>> Function() clearRefresh,
    required DirectoryMetadataService? directoryMetadata,
    required DirectoryTagService? directoryTags,
    required FavoritePostSourceService? favoritePosts,
    required LocalTagsService? localTags,
    required Directories parent,
  }) {
    return _FakeFiles(
      clearRefresh,
      directoryMetadata,
      directoryTags,
      favoritePosts,
      localTags,
      parent,
    );
  }

  DirectoryTagService? get directoryTags;
  DirectoryMetadataService? get directoryMetadata;
  FavoritePostSourceService? get favoritePosts;
  LocalTagsService? get localTags;

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

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

mixin class GalleryService implements ServiceMarker {
  const GalleryService();

  static bool get available => _instance != null;
  static GalleryService? safe() => _instance;

  // ignore: unnecessary_late
  static late final _instance = _dbInstance.get<GalleryService>();

  GalleryTrash get trash => _instance!.trash;

  Directories open() => _instance!.open();
}

abstract class Directory implements DirectoryBase, DirectoryImpl {
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

abstract class File implements FileBase, FileImpl {
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

abstract class Directories {
  ResourceSource<int, Directory> get source;
  TrashCell? get trashCell;

  Files? get bindFiles;

  Files files(
    Directory directory,
    GalleryFilesPageType type, {
    required String bucketId,
    required String name,
  });

  Files joinedFiles(List<Directory> directories);

  void close();
}

abstract class Files {
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

abstract interface class GalleryTrash {
  Future<Directory?> get thumb;

  void addAll(List<String> uris);

  void empty();

  void removeAll(List<String> uris);
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

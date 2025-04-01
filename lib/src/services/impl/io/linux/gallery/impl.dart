// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io" as io;

import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/trash_cell.dart";
import "package:azari/src/services/services.dart";
import "package:mime/mime.dart";
import "package:path/path.dart" as path;

class LinuxGalleryApi implements GalleryService {
  const LinuxGalleryApi();

  @override
  Directories open() => _Directories();

  @override
  GalleryTrash get trash => const _GalleryTrash();
}

class _GalleryTrash implements GalleryTrash {
  const _GalleryTrash();

  @override
  void addAll(List<String> uris) {
    // TODO: implement addAll
  }

  @override
  void empty() {
    // TODO: implement empty
  }

  @override
  void removeAll(List<String> uris) {
    // TODO: implement removeAll
  }

  @override
  // TODO: implement thumb
  Future<Directory?> get thumb => Future.value();
}

class _Directories implements Directories {
  _Directories();

  final trash = GalleryService.safe()?.trash;

  @override
  late final TrashCell? trashCell = trash != null ? TrashCell(trash!) : null;

  @override
  Files? bindFiles;

  @override
  Files files(
    Directory directory,
    GalleryFilesPageType type, {
    required String name,
    required String bucketId,
  }) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    return bindFiles = _Files(
      directories: [directory],
      parent: this,
      bucketId: bucketId,
      type: type,
    );
  }

  @override
  Files joinedFiles(List<Directory> directories) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    return bindFiles = _Files(
      directories: directories,
      parent: this,
      bucketId: "joinedDir",
      type: GalleryFilesPageType.normal,
    );
  }

  @override
  late final ResourceSource<int, Directory> source = _LinuxResourceSource();

  @override
  void close() {
    source.destroy();
    trashCell?.dispose();
  }
}

class _LinuxResourceSource implements ResourceSource<int, Directory> {
  _LinuxResourceSource();

  @override
  bool get hasNext => false;

  @override
  final ListStorage<Directory> backingStorage = ListStorage();

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;

    final settings = const SettingsService().current;
    if (settings.path.path.isNotEmpty) {
      try {
        final dir = io.Directory(settings.path.path);
        final exist = await dir.exists();
        if (!exist) {
          throw "directory do not exist";
        }

        await for (final e in dir.list(followLinks: false)) {
          backingStorage.add(
            Directory(
              bucketId: e.path,
              name: path.basename(e.path),
              tag: DirectoryTagService.safe()?.get(e.path) ?? "",
              volumeName: "",
              relativeLoc: path.dirname(e.path),
              lastModified: (await e.stat()).modified.millisecondsSinceEpoch,
              thumbFileId: 0,
            ),
            false,
          );
        }
      } catch (e) {
        progress.error = e;
      }
    }

    backingStorage.addAll([]);

    progress.inRefreshing = false;

    return count;
  }

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    backingStorage.destroy();
    progress.close();
  }
}

class _Files implements Files {
  _Files({
    required this.bucketId,
    required this.directories,
    required this.parent,
    required this.type,
  });

  @override
  final List<Directory> directories;

  @override
  final GalleryFilesPageType type;

  @override
  final _Directories parent;

  @override
  final String bucketId;

  @override
  late final SortingResourceSource<int, File> source =
      _LinuxFilesSource(directories);

  @override
  MapFilesSourceTags sourceTags = MapFilesSourceTags();

  @override
  void close() {
    parent.bindFiles = null;
    source.destroy();
    sourceTags.dispose();
  }
}

class _LinuxFilesSource implements SortingResourceSource<int, File> {
  _LinuxFilesSource(this.directories);

  final List<Directory> directories;

  final localTags = LocalTagsService.safe();

  @override
  bool get hasNext => false;

  @override
  final ListStorage<File> backingStorage = ListStorage();

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return count;
    }
    progress.inRefreshing = true;

    try {
      for (final dirPath in directories) {
        final dir = io.Directory(dirPath.bucketId);
        final exist = await dir.exists();
        if (!exist) {
          continue;
        }

        await for (final e in dir.list(followLinks: false)) {
          final name = path.basename(e.path);
          final mime = lookupMimeType(name);
          if (mime == null || mime.split("/").first != "image") {
            continue;
          }

          final s = await e.stat();

          backingStorage.add(
            File(
              tags: localTags != null
                  ? localTags!.get(name).fold({}, (map, e) {
                      map[e] = null;

                      return map;
                    })
                  : const {},
              id: 0,
              bucketId: dirPath.bucketId,
              name: name,
              isVideo: false,
              isGif: path.extension(name) == ".gif",
              size: s.size,
              height: 0,
              isDuplicate: false,
              width: 0,
              lastModified: (s.modified.millisecondsSinceEpoch / 1000).round(),
              originalUri: e.path,
              res: ParsedFilenameResult.simple(name),
            ),
            false,
          );
        }
      }
    } catch (e) {
      progress.error = e;
    }

    backingStorage.addAll([]);

    progress.inRefreshing = false;

    return count;
  }

  @override
  SortingMode get sortingMode => SortingMode.none;

  @override
  set sortingMode(SortingMode s) {}

  @override
  Future<int> next() => Future.value(count);

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  void destroy() {
    progress.close();
    backingStorage.destroy();
  }

  @override
  Future<int> clearRefreshSilent() => clearRefresh();
}


// class LinuxDirectory extends Directory {
//   const LinuxDirectory({
//     required super.bucketId,
//     required super.name,
//     required super.tag,
//     required super.volumeName,
//     required super.relativeLoc,
//     required super.lastModified,
//     required super.thumbFileId,
//   });
// }



// class LinuxFile extends File {
//   const LinuxFile({
//     required super.tags,
//     required super.id,
//     required super.bucketId,
//     required super.name,
//     required super.isVideo,
//     required super.isGif,
//     required super.size,
//     required super.height,
//     required super.isDuplicate,
//     required super.width,
//     required super.lastModified,
//     required super.originalUri,
//     required super.res,
//   });
// }

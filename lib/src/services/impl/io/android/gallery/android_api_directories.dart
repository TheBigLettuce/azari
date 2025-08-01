// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_gallery.dart";

class _AndroidGallery implements Directories {
  _AndroidGallery() {
    _eventsNotify = const GalleryApi().events.notify?.listen((target) {
      for (final bindFiles in _activeFiles) {
        if (target == null || target == bindFiles.target) {
          bindFiles.source.clearRefresh();
        }
      }

      source.clearRefresh();
    });
  }

  late final StreamSubscription<String?>? _eventsNotify;

  final trash = GalleryService.safe()?.trash;

  final time = DateTime.now();

  bool isThumbsLoading = false;

  final List<_AndroidGalleryFiles> _activeFiles = [];

  @override
  bool get isHostingFiles => _activeFiles.isNotEmpty;

  @override
  TrashCell? get trashCell => source.trashCell;

  @override
  late final _AndroidSource source = _AndroidSource(
    trash != null ? TrashCell(trash!) : null,
  );

  @override
  void close() {
    _eventsNotify?.cancel();
    source.destroy();
    trashCell?.dispose();
    // e.close() removes from _activeFiles
    for (final e in _activeFiles.toList()) {
      e.close();
    }
    _activeFiles.clear();
  }

  @override
  Files files(
    Directory directory,
    GalleryFilesPageType type, {
    required String bucketId,
    required String name,
  }) {
    final sourceTags = MapFilesSourceTags();
    final files = _AndroidGalleryFiles(
      source: _AndroidFileSourceJoined([directory], type, sourceTags),
      sourceTags: sourceTags,
      directories: [directory],
      target: name,
      type: type,
      parent: this,
      bucketId: bucketId,
    );
    _activeFiles.add(files);

    return files;
  }

  @override
  Files joinedFiles(List<Directory> directories) {
    final sourceTags = MapFilesSourceTags();
    final files = _JoinedDirectories(
      source: _AndroidFileSourceJoined(
        directories,
        GalleryFilesPageType.normal,
        sourceTags,
      ),
      sourceTags: sourceTags,
      directories: directories,
      parent: this,
    );
    _activeFiles.add(files);

    return files;
  }
}

class _AndroidSource implements ResourceSource<int, Directory> {
  _AndroidSource(this.trashCell);

  final TrashCell? trashCell;

  @override
  bool get hasNext => false;

  @override
  final ClosableRefreshProgress progress = ClosableRefreshProgress();

  @override
  final SourceStorage<int, Directory> backingStorage = ListStorage();

  final cursorApi = platform.DirectoriesCursor();

  @override
  Future<int> clearRefresh() async {
    if (progress.inRefreshing) {
      return Future.value(count);
    }
    progress.inRefreshing = true;

    backingStorage.clear();
    trashCell?.refresh();

    final token = await cursorApi.acquire();
    try {
      while (true) {
        final e = await cursorApi.advance(token);
        if (e.isEmpty) {
          break;
        }

        final blacklisted =
            BlacklistedDirectoryService.safe()?.getAll(
              e.keys.map((e) => e).toList(),
            ) ??
            const [];
        for (final b in blacklisted) {
          e.remove(b.bucketId);
        }

        backingStorage.addAll(
          e.values
              .map(
                (e) => Directory(
                  bucketId: e.bucketId,
                  name: e.name,
                  tag: DirectoryTagService.safe()?.get(e.bucketId) ?? "",
                  volumeName: e.volumeName,
                  relativeLoc: e.relativeLoc,
                  thumbFileId: e.thumbFileId,
                  lastModified: e.lastModified,
                ),
              )
              .toList(),
          true,
        );
      }
    } catch (e, trace) {
      Logger.root.severe("_AndroidSource", e, trace);
    } finally {
      await cursorApi.destroy(token);
    }

    progress.inRefreshing = false;
    backingStorage.addAll([]);

    return Future.value(count);
  }

  @override
  Future<int> next() => Future.value(count);

  @override
  void destroy() {
    trashCell?.dispose();
    backingStorage.destroy();
    progress.close();
  }
}

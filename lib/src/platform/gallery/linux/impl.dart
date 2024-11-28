// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io" as io;

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/platform/gallery/io.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:file_picker/file_picker.dart";
import "package:mime/mime.dart";
import "package:path/path.dart" as path;

class LinuxGalleryApi implements GalleryApi {
  const LinuxGalleryApi();

  @override
  Future<int> get version => Future.value(0);

  @override
  Directories open(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    required AppLocalizations l10n,
  }) {
    return _Directories(
      blacklistedDirectory: blacklistedDirectory,
      directoryTag: directoryTag,
      l10n: l10n,
    );
  }

  @override
  void notify(String? target) {}

  @override
  Future<({String path, String formattedPath})?> chooseDirectory(
    AppLocalizations l10n, {
    bool temporary = false,
  }) {
    return FilePicker.platform
        .getDirectoryPath(dialogTitle: l10n.pickDirectory)
        .then((e) => e == null ? null : (path: e, formattedPath: e));
  }

  @override
  GalleryTrash get trash => const GalleryTrash.dummy();

  @override
  CachedThumbs get thumbs => const CachedThumbs.dummy();

  @override
  FilesManagement get files => const IoFilesManagement();

  @override
  Events get events => const Events.none();

  @override
  Search get search => const Search.dummy();
}

class _Directories implements Directories {
  _Directories({
    required this.l10n,
    required this.blacklistedDirectory,
    required this.directoryTag,
  });

  final BlacklistedDirectoryService blacklistedDirectory;
  final DirectoryTagService directoryTag;
  final AppLocalizations l10n;

  @override
  late final TrashCell trashCell = TrashCell(l10n);

  @override
  Files? bindFiles;

  @override
  Files files(
    Directory directory,
    GalleryFilesPageType type,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoritePostSourceService favoritePosts,
    LocalTagsService localTags, {
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
      directoryMetadata: directoryMetadata,
      directoryTag: directoryTag,
      favoritePosts: favoritePosts,
      localTags: localTags,
    );
  }

  @override
  Files joinedFiles(
    List<Directory> directories,
    DirectoryTagService directoryTag,
    DirectoryMetadataService directoryMetadata,
    FavoritePostSourceService favoritePosts,
    LocalTagsService localTags,
  ) {
    if (bindFiles != null) {
      throw "already hosting files";
    }

    return bindFiles = _Files(
      directories: directories,
      parent: this,
      bucketId: "joinedDir",
      type: GalleryFilesPageType.normal,
      directoryMetadata: directoryMetadata,
      directoryTag: directoryTag,
      favoritePosts: favoritePosts,
      localTags: localTags,
    );
  }

  @override
  late final ResourceSource<int, Directory> source =
      _LinuxResourceSource(directoryTag);

  @override
  void close() {
    source.destroy();
    trashCell.dispose();
  }
}

class _LinuxResourceSource implements ResourceSource<int, Directory> {
  _LinuxResourceSource(this.directoryTag);

  final DirectoryTagService directoryTag;

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

    final settings = SettingsService.db().current;
    if (settings.path.path.isNotEmpty) {
      try {
        final dir = io.Directory(settings.path.path);
        final exist = await dir.exists();
        if (!exist) {
          throw "directory do not exist";
        }

        await for (final e in dir.list(followLinks: false)) {
          backingStorage.add(
            LinuxDirectory(
              bucketId: e.path,
              name: path.basename(e.path),
              tag: directoryTag.get(e.path) ?? "",
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

class LinuxDirectory extends Directory {
  const LinuxDirectory({
    required super.bucketId,
    required super.name,
    required super.tag,
    required super.volumeName,
    required super.relativeLoc,
    required super.lastModified,
    required super.thumbFileId,
  });
}

class _Files implements Files {
  _Files({
    required this.bucketId,
    required this.directories,
    required this.parent,
    required this.type,
    required this.directoryMetadata,
    required this.directoryTag,
    required this.favoritePosts,
    required this.localTags,
  });

  @override
  final List<Directory> directories;

  @override
  final GalleryFilesPageType type;

  @override
  final DirectoryMetadataService directoryMetadata;

  @override
  final DirectoryTagService directoryTag;

  @override
  final FavoritePostSourceService favoritePosts;

  @override
  final LocalTagsService localTags;

  @override
  final _Directories parent;

  @override
  final String bucketId;

  @override
  late final SortingResourceSource<int, File> source =
      _LinuxFilesSource(directories, localTags);

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
  _LinuxFilesSource(this.directories, this.localTags);

  final LocalTagsService localTags;

  final List<Directory> directories;

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
            LinuxFile(
              tags: localTags.get(name).fold({}, (map, e) {
                map[e] = null;

                return map;
              }),
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

class LinuxFile extends File {
  const LinuxFile({
    required super.tags,
    required super.id,
    required super.bucketId,
    required super.name,
    required super.isVideo,
    required super.isGif,
    required super.size,
    required super.height,
    required super.isDuplicate,
    required super.width,
    required super.lastModified,
    required super.originalUri,
    required super.res,
  });

  @override
  Contentable content() => EmptyContent(this);
}

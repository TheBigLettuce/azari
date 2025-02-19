// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_gallery.dart";

class AndroidFilesManagement implements FilesManagement {
  const AndroidFilesManagement();

  @override
  Future<void> moveSingle({
    required String source,
    required String rootDir,
    required String targetDir,
  }) {
    return AndroidGalleryApi.appContext.invokeMethod(
      "move",
      {"source": source, "rootUri": rootDir, "dir": targetDir},
    );
  }

  @override
  void deleteAll(List<File> selected) {
    AndroidGalleryApi.activityContext.invokeMethod(
      "deleteFiles",
      selected.map((e) => e.originalUri).toList(),
    );
  }

  @override
  Future<bool> exists(String filePath) => io.File(filePath).exists();

  @override
  Future<void> copyMove(
    String chosen,
    String chosenVolumeName,
    List<File> selected, {
    required bool move,
    required bool newDir,
  }) {
    return AndroidGalleryApi.activityContext.invokeMethod(
      "copyMoveFiles",
      {
        "dest": chosen,
        "images": selected
            .where((element) => !element.isVideo)
            .map((e) => e.id)
            .toList(),
        "videos": selected
            .where((element) => element.isVideo)
            .map((e) => e.id)
            .toList(),
        "move": move,
        "volumeName": chosenVolumeName,
        "newDir": newDir,
      },
    );
  }

  @override
  Future<void> rename(String uri, String newName, [bool notify = true]) {
    if (newName.isEmpty) {
      return Future.value();
    }

    AndroidGalleryApi.activityContext.invokeMethod(
      "rename",
      {"uri": uri, "newName": newName, "notify": notify},
    );

    return Future.value();
  }

  @override
  Future<void> copyMoveInternal({
    required String relativePath,
    required String volume,
    required String dirName,
    required List<String> internalPaths,
  }) {
    final List<String> images = [];
    final List<String> videos = [];

    for (final e in internalPaths) {
      final type = PostContentType.fromUrl(e);
      if (type == PostContentType.gif || type == PostContentType.image) {
        images.add(e);
      } else if (type == PostContentType.video) {
        videos.add(e);
      }
    }

    return AndroidGalleryApi.activityContext.invokeMethod(
      "copyMoveInternal",
      {
        "dirName": dirName,
        "relativePath": relativePath,
        "images": images,
        "videos": videos,
        "volume": volume,
      },
    );
  }
}

class AndroidCachedThumbs implements CachedThumbs {
  const AndroidCachedThumbs();

  @override
  Future<int> size([bool fromPinned = false]) {
    return AndroidGalleryApi.appContext
        .invokeMethod("thumbCacheSize", fromPinned)
        .then((value) => value as int);
  }

  @override
  Future<ThumbId> get(int id) {
    return AndroidGalleryApi.appContext.invokeMethod("getCachedThumb", id).then(
      (value) {
        return ThumbId(
          id: id,
          path: (value as Map)["path"] as String,
          differenceHash: value["hash"] as int,
        );
      },
    );
  }

  @override
  void clear([bool fromPinned = false]) => AndroidGalleryApi.appContext
      .invokeMethod("clearCachedThumbs", fromPinned);

  @override
  void removeAll(List<int> id, [bool fromPinned = false]) {
    AndroidGalleryApi.appContext.invokeMethod(
      "deleteCachedThumbs",
      {"ids": id, "fromPinned": fromPinned},
    );
  }

  @override
  Future<ThumbId> saveFromNetwork(String url, int id) {
    return AndroidGalleryApi.appContext
        .invokeMethod("saveThumbNetwork", {"url": url, "id": id}).then(
      (value) => ThumbId(
        id: id,
        path: (value as Map)["path"] as String,
        differenceHash: value["hash"] as int,
      ),
    );
  }
}

class AndroidGalleryTrash implements GalleryTrash {
  const AndroidGalleryTrash();

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

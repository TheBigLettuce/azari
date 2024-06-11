// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_api_directories.dart";

class AndroidGallery implements GalleryPlug {
  const AndroidGallery();

  @override
  Future<int> get version =>
      const AndroidApiFunctions().currentMediastoreVersion();

  @override
  bool get temporary => _global!.temporary;

  @override
  GalleryAPIDirectories galleryApi(
    BlacklistedDirectoryService blacklistedDirectory,
    DirectoryTagService directoryTag, {
    required AppLocalizations l10n,
  }) {
    final api = _AndroidGallery(
      blacklistedDirectory,
      directoryTag,
      localizations: l10n,
    );
    _global!._currentApi = api;

    return api;
  }

  @override
  void notify(String? target) {
    _global!.notify(target);
  }

  @override
  GalleryDirectory makeGalleryDirectory({
    required int thumbFileId,
    required String bucketId,
    required String name,
    required String relativeLoc,
    required String volumeName,
    required int lastModified,
    required String tag,
  }) =>
      AndroidGalleryDirectory(
        bucketId: bucketId,
        name: name,
        tag: tag,
        volumeName: volumeName,
        relativeLoc: relativeLoc,
        lastModified: lastModified,
        thumbFileId: thumbFileId,
      );

  @override
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
  }) =>
      AndroidGalleryFile(
        id: id,
        bucketId: bucketId,
        name: name,
        isVideo: isVideo,
        isGif: isGif,
        size: size,
        height: height,
        isDuplicate: isDuplicate,
        width: width,
        lastModified: lastModified,
        originalUri: originalUri,
        tagsFlat: tagsFlat,
      );
}

void initalizeAndroidGallery(bool temporary) {
  if (_global == null) {
    GalleryApi.setup(_GalleryImpl(temporary));
  }
}

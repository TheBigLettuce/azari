// SPDX-License-Identifier: GPL-2.0-only
//
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
    required bool temporaryDb,
    bool setCurrentApi = true,
    required AppLocalizations l8n,
  }) {
    final api = _AndroidGallery(
      blacklistedDirectory,
      directoryTag,
      temporary: temporaryDb,
      localizations: l8n,
    );
    _global!._currentApi = api;

    // if (setCurrentApi) {
    //   _global!._setCurrentApi(api);
    // } else {
    //   _global!._temporaryApis.add(api);
    // }

    return api;
  }

  @override
  void notify(String? target) {
    _global!.notify(target);
  }
}

void initalizeAndroidGallery(bool temporary) {
  if (_global == null) {
    GalleryApi.setup(_GalleryImpl(temporary));
  }
}

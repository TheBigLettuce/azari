// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'android_api_directories.dart';

class AndroidGallery implements GalleryPlug {
  @override
  bool get temporary => _global!.temporary;

  @override
  GalleryAPIDirectories galleryApi(
      {bool? temporaryDb, bool setCurrentApi = true}) {
    final api = _AndroidGallery(temporary: temporaryDb);
    if (setCurrentApi) {
      _global!._setCurrentApi(api);
    } else {
      _global!._temporaryApis.add(api);
    }

    return api;
  }

  @override
  void notify(String? target) {
    _global!.notify(target);
  }

  const AndroidGallery();
}

void initalizeAndroidGallery(bool temporary) {
  if (_global == null) {
    GalleryApi.setup(_GalleryImpl(temporary));
  }
}

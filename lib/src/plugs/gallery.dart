// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:io";

import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";

import "package:gallery/src/plugs/gallery/android/android_api_directories.dart";
import "package:gallery/src/plugs/gallery/dummy.dart";

abstract class GalleryPlug {
  GalleryAPIDirectories galleryApi({
    bool? temporaryDb,
    bool setCurrentApi = true,
  });
  void notify(String? target);
  bool get temporary;
  Future<int> get version;
}

GalleryPlug chooseGalleryPlug() {
  if (Platform.isAndroid) {
    return const AndroidGallery();
  }

  return DummyGallery();
}

void initalizeGalleryPlug(bool temporary) {
  if (Platform.isAndroid) {
    initalizeAndroidGallery(temporary);
  }
}

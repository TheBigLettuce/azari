// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "android_gallery.dart";

class AndroidGalleryDirectory extends Directory {
  const AndroidGalleryDirectory({
    required super.bucketId,
    required super.name,
    required super.tag,
    required super.volumeName,
    required super.relativeLoc,
    required super.lastModified,
    required super.thumbFileId,
  });
}

class AndroidGalleryFile extends File {
  const AndroidGalleryFile({
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
    required super.tags,
    required super.res,
  });
}

class _GalleryImpl implements platform.PlatformGalleryApi {
  factory _GalleryImpl() {
    if (_impl != null) {
      return _impl!;
    }

    platform.PlatformGalleryApi.setUp(_impl = _GalleryImpl._new());

    return _impl!;
  }

  _GalleryImpl._new();

  static _GalleryImpl? _impl;

  final List<_AndroidGallery> liveInstances = [];

  @override
  void notify(String? target) {
    for (final e in liveInstances) {
      if (target == null || target == e.bindFiles?.target) {
        e.bindFiles?.source.clearRefresh();
      }

      e.source.clearRefresh();
    }
  }

  @override
  void notifyNetworkStatus(bool hasInternet) {
    if (NetworkStatus.g.hasInternet != hasInternet) {
      NetworkStatus.g.hasInternet = hasInternet;
      NetworkStatus.g.notify?.call();
    }
  }

  @override
  void galleryTapDownEvent() {
    _Events._tapDown.add(null);
  }

  @override
  void galleryPageChangeEvent(platform.GalleryPageChangeEvent e) {
    _Events._pageChange.add(e);
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/platform/gallery_api.dart";
import "package:flutter/widgets.dart";

extension GalleryReturnTypeCheckersExt on GalleryReturnCallback {
  bool get isDirectory => this is ReturnDirectoryCallback;
  bool get isFile => this is ReturnFileCallback;

  ReturnDirectoryCallback get toDirectory => this as ReturnDirectoryCallback;
  ReturnFileCallback get toFile => this as ReturnFileCallback;

  ReturnFileCallback? get toFileOrNull =>
      this is ReturnFileCallback ? this as ReturnFileCallback : null;
}

sealed class GalleryReturnCallback {
  const GalleryReturnCallback({
    required this.preview,
  });

  final PreferredSizeWidget preview;
}

class ReturnDirectoryCallback extends GalleryReturnCallback {
  const ReturnDirectoryCallback({
    required super.preview,
    required this.joinable,
    required this.suggestFor,
    required this.choose,
  });

  final Future<void> Function(
    ({
      String path,
      String volumeName,
      String bucketId,
    }) e,
    bool newDir,
  ) choose;

  final bool joinable;

  final List<String> suggestFor;

  Future<void> call(
    ({
      String path,
      String volumeName,
      String bucketId,
    }) e,
    bool newDir,
  ) =>
      choose(e, newDir);
}

class ReturnFileCallback extends GalleryReturnCallback {
  const ReturnFileCallback({
    this.returnBack = false,
    required super.preview,
    required this.choose,
  });

  final Future<void> Function(File file) choose;

  final bool returnBack;

  Future<void> call(File file) => choose(file);
}

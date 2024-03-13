// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/system_gallery_thumbnail_provider.dart';
import 'package:isar/isar.dart';

import '../../../interfaces/cell/cell.dart';
import '../../../interfaces/cell/contentable.dart';
import '../../../interfaces/cell/sticker.dart';

part 'system_gallery_directory.g.dart';

@collection
class SystemGalleryDirectory implements Cell {
  SystemGalleryDirectory({
    required this.bucketId,
    required this.name,
    required this.tag,
    required this.volumeName,
    required this.relativeLoc,
    required this.lastModified,
    required this.thumbFileId,
  });

  @override
  Id? isarId;

  final int thumbFileId;
  @Index(unique: true)
  final String bucketId;

  @Index()
  final String name;

  final String relativeLoc;
  final String volumeName;

  @Index()
  final int lastModified;

  @Index()
  final String tag;

  @override
  Contentable content() => const EmptyContent();

  @override
  ImageProvider<Object>? thumbnail() =>
      SystemGalleryThumbnailProvider(thumbFileId, true);

  @override
  Key uniqueKey() => ValueKey(bucketId);

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  Widget? contentInfo(BuildContext context) => null;

  @override
  String alias(bool isList) => name;

  @override
  String? fileDownloadUrl() => null;

  @override
  List<Sticker> stickers(BuildContext context) => const [];

  static SystemGalleryDirectory decode(Object result) {
    result as List<Object?>;

    final bucketId = result[1]! as String;

    return SystemGalleryDirectory(
      // isarId: id,
      tag: "",
      thumbFileId: result[0]! as int,
      bucketId: bucketId,
      name: result[2]! as String,
      relativeLoc: result[3]! as String,
      volumeName: result[4]! as String,
      lastModified: result[5]! as int,
    );
  }
}

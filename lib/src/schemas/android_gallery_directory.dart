// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:isar/isar.dart';

import '../cell/cell.dart';
import '../cell/contentable.dart';
import 'android_gallery_directory_file.dart';

part 'android_gallery_directory.g.dart';

@collection
class SystemGalleryDirectory implements Cell {
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

  SystemGalleryDirectory(
      {required this.bucketId,
      required this.name,
      required this.tag,
      required this.volumeName,
      required this.relativeLoc,
      required this.lastModified,
      required this.thumbFileId});

  @ignore
  @override
  List<Widget>? Function(BuildContext context) get addButtons => (_) => null;

  @ignore
  @override
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo => (_, __, ___) {
            return null;
          };

  @override
  String alias(bool isList) => name;

  @override
  Contentable fileDisplay() => const EmptyContent();

  @override
  String fileDownloadUrl() => "";

  @override
  CellData getCellData(bool isList) {
    return CellData(
        thumb: ThumbnailProvider(thumbFileId), name: name, stickers: []);
  }
}

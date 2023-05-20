// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

import '../cell/booru.dart';

part 'post.g.dart';

@collection
class Post {
  Id? isarId;

  @Index(unique: true, replace: true)
  final int id;

  final String md5;
  final String tags;

  final int width;
  final int height;

  final String fileUrl;
  final String previewUrl;
  final String sampleUrl;

  final String ext;

  String filename() => "$id - $md5$ext";

  BooruCell booruCell(void Function(String tag) onTagPressed) => BooruCell(
      postNumber: id.toString(),
      sampleUrl: sampleUrl,
      path: previewUrl,
      originalUrl: fileUrl,
      tags: tags,
      onTagPressed: onTagPressed);

  Post(
      {required this.height,
      required this.id,
      required this.md5,
      required this.tags,
      required this.width,
      required this.fileUrl,
      required this.previewUrl,
      required this.sampleUrl,
      required this.ext});
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:isar/isar.dart';

part 'directory.g.dart';

@collection
class Directory implements Cell<Directory> {
  @override
  Id? isarId;

  @Index(unique: true)
  String dirPath;
  String imageUrl;
  @Index()
  String dirName;
  // String id;
  int time;

  int count;

  @override
  String alias(bool isList) => "$dirName ($count)";

  @override
  Content fileDisplay() => throw "not implemented";

  @override
  String fileDownloadUrl() => dirPath;

  @override
  CellData getCellData(bool isList) => CellData(
      thumb: CachedNetworkImageProvider(imageUrl),
      name: alias(isList),
      stickers: []);

  @ignore
  @override
  List<Widget>? Function() get addButtons => () {
        return null;
      };

  @ignore
  @override
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo => (_, __, ___) {
            return null;
          };

  Directory(
      {required this.imageUrl,
      required this.dirPath,
      required this.dirName,
      required this.time,
      required this.count});

  @override
  shrinkedData() => this;
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';

import '../cell/directory.dart';
import '../gallery/android_api/api.g.dart' as gallery;

part 'directory.g.dart';

@collection
class Directory extends gallery.Directory {
  Id? isarId;

  @Index(unique: true, replace: true)
  String id;

  DirectoryCell cell() => DirectoryCell(
        id: id,
        image: MemoryImage(Uint8List.fromList(thumbnail.cast())),
        dirPath: name,
        dirName: name,
      );

  Directory(this.id,
      {required int lastModified,
      required List<int?> thumbnail,
      required String name})
      : super(lastModified: lastModified, thumbnail: thumbnail, name: name);
}

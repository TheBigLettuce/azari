// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:convert/convert.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:isar/isar.dart';

part 'directory.g.dart';

String _fromBaseToHex(String v) {
  return hex.encode(base64Decode(v));
}

@collection
class Directory implements Cell<Directory> {
  @override
  Id? isarId;

  @Index(unique: true)
  final String dirPath;
  final String imageHash;
  @Index()
  final String dirName;
  final int time;
  final String serverUrl;

  final int count;

  @ignore
  String get imageUrl => Uri.parse(serverUrl)
      .replace(path: '/static/${_fromBaseToHex(imageHash)}')
      .toString();

  Directory copy(
          {String? imageHash,
          String? dirPath,
          String? dirName,
          int? time,
          String? serverUrl,
          int? count}) =>
      Directory(
          imageHash: imageHash ?? this.imageHash,
          dirPath: dirPath ?? this.dirPath,
          dirName: dirName ?? this.dirName,
          serverUrl: serverUrl ?? this.serverUrl,
          time: time ?? this.time,
          count: count ?? this.count);

  @override
  String alias(bool isList) => "$dirName ($count)";

  @override
  Contentable fileDisplay() => const EmptyContent();

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
      {required this.imageHash,
      required this.serverUrl,
      required this.dirPath,
      required this.dirName,
      required this.time,
      required this.count});

  @override
  shrinkedData() => this;
}

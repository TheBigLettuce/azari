// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';

import 'data.dart';

enum ContentType { image, video }

class Content {
  ContentType type;
  bool isVideoLocal;

  ImageProvider? image;

  String? videoPath;

  Content(this.type, this.isVideoLocal, {this.image, this.videoPath});
}

class AddInfoColorData {
  final Color borderColor;
  final Color foregroundColor;
  final Color systemOverlayColor;

  const AddInfoColorData({
    required this.borderColor,
    required this.foregroundColor,
    required this.systemOverlayColor,
  });
}

abstract class Cell<B> {
  //String get path;

  String alias(bool isList);

  @ignore
  List<Widget>? Function(
      BuildContext context, dynamic extra, AddInfoColorData colors) get addInfo;

  @ignore
  List<Widget>? Function() get addButtons;

  Content fileDisplay();

  String fileDownloadUrl();

  CellData getCellData(bool isList);

  B shrinkedData();
  //Cell({required this.path, required this.addInfo, required this.addButtons});
}

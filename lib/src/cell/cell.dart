// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';

import 'data.dart';

enum ContentType { image, video, androidImage, androidGif }

sealed class Contentable {
  const Contentable();
}

class EmptyContent extends Contentable {
  const EmptyContent();
}

class AndroidGif extends Contentable {
  final String uri;
  final Size size;

  const AndroidGif({required this.uri, required this.size});
}

class AndroidVideo extends Contentable {
  final String uri;
  final Size size;

  const AndroidVideo({required this.uri, required this.size});
}

class AndroidImage extends Contentable {
  final String uri;
  final Size size;

  const AndroidImage({required this.uri, required this.size});
}

class NetImage extends Contentable {
  final ImageProvider provider;

  const NetImage(this.provider);
}

class NetGif extends Contentable {
  final ImageProvider provider;

  const NetGif(this.provider);
}

class NetVideo extends Contentable {
  final String uri;

  const NetVideo(this.uri);
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

  int? get isarId;
  set isarId(int? i);

  String alias(bool isList);

  @ignore
  List<Widget>? Function(
      BuildContext context, dynamic extra, AddInfoColorData colors) get addInfo;

  @ignore
  List<Widget>? Function() get addButtons;

  Contentable fileDisplay();

  String fileDownloadUrl();

  CellData getCellData(bool isList);

  B shrinkedData();
  //Cell({required this.path, required this.addInfo, required this.addButtons});
}

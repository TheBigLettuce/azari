// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:isar/isar.dart';

import '../../db/schemas/gallery/system_gallery_directory_file.dart';
import 'contentable.dart';
import 'sticker.dart';

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

/// Cells on a grid.
/// Implementations of this interface can be presented on the [CallbackGrid].
/// This can be not only a cell on a grid, it can be also an element in a list.
/// [CallbackGrid] decides how this gets displayed.
abstract class Cell {
  /// Common pattern of the implementations of [Cell] is that they are all an Isar schema.
  /// However, this property can be ignored, together with the setter.
  /// This is only useful for the internal implementations, not used in the [CallbackGrid].
  /// No asumptions can be made about this property.
  int? get isarId;
  set isarId(int? i);

  /// The name of the cell, displayed on top of the cell.
  /// If [isList] is true, it means the cell gets displayed as a list entry,
  /// instead of a cell on a grid.
  String alias(bool isList);

  /// Additional information about the cell.
  /// This gets displayed in the "Info" list view, in the image view.
  List<Widget>? addInfo(
      BuildContext context, dynamic extra, AddInfoColorData colors);

  /// Additional buttons which get diplayed in the image view's appbar.
  List<Widget>? addButtons(BuildContext context);

  List<(IconData, void Function()?)>? addStickers(BuildContext context);

  /// File that gets displayed in the image view.
  /// This can be unimplemented.
  /// Not implementing this assumes that clicking on the grid will take to an other page,
  /// requires [CallbackGrid.overrideOnPress] to be not null, which makes [fileDisplay] never to be called.
  Contentable content();

  ImageProvider? thumbnail();

  /// Url to the file to download.
  /// This can be unimplemented.
  /// Not implementing this assumes that clicking on the grid will take to an other page,
  /// requires [CallbackGrid.overrideOnPress] to be not null, which makes [fileDownloadUrl] never to be called.
  String? fileDownloadUrl();

  List<Sticker> stickers(BuildContext context);

  Key uniqueKey();

  /// Const constructor to allow implementations to have const constructors.
  const Cell();
}

mixin CachedCellValuesMixin on Cell {
  @ignore
  late final Key _key;
  @ignore
  late final String? _thumbUrl;
  @ignore
  late final Contentable Function() _contentInit;

  @ignore
  ImageProvider? _thumb;
  @ignore
  Contentable? _content;

  void initValues(Key key, String? thumbUrl, Contentable Function() content) {
    _key = key;
    _thumbUrl = thumbUrl;
    _contentInit = content;
  }

  @override
  Key uniqueKey() => _key;

  @override
  Contentable content() {
    if (_content != null) {
      return _content!;
    }

    _content = _contentInit();

    return _content!;
  }

  @override
  ImageProvider? thumbnail() {
    if (_thumbUrl == null) {
      return null;
    }

    if (_thumb != null) {
      return _thumb!;
    }

    _thumb = CachedNetworkImageProvider(_thumbUrl!);

    return _thumb;
  }
}

mixin CachedCellValuesFilesMixin on Cell {
  late final Key _key;
  late final (int id, bool tryLoad) _thumbInit;
  late final Contentable Function() _contentInit;

  ThumbnailProvider? _thumb;
  Contentable? _content;

  void initValues(
      Key key, (int id, bool tryLoad) thumb, Contentable Function() content) {
    _key = key;
    _thumbInit = thumb;
    _contentInit = content;
  }

  @override
  Key uniqueKey() => _key;

  @override
  Contentable content() {
    if (_content != null) {
      return _content!;
    }

    _content = _contentInit();

    return _content!;
  }

  @override
  ImageProvider? thumbnail() {
    if (_thumb != null) {
      return _thumb!;
    }

    _thumb = ThumbnailProvider(_thumbInit.$1, _thumbInit.$2);

    return _thumb;
  }
}

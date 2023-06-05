// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';

import 'cell.dart';
import 'data.dart';

class DirectoryCell implements Cell {
  String dirPath;
  ImageProvider image;
  String dirName;
  String id;

  @override
  String alias(bool isList) => dirName;

  @override
  Content fileDisplay() => throw "not implemented";

  @override
  String fileDownloadUrl() => dirName;

  @override
  CellData getCellData(bool isList) =>
      CellData(thumb: image, name: alias(isList));

  @override
  List<Widget>? Function() get addButtons => () {
        return null;
      };

  @override
  List<Widget>? Function(BuildContext context, dynamic extra, Color borderColor,
          Color foregroundColor, Color systemOverlayColor)
      get addInfo => (_, __, ___, ____, _____) {
            return null;
          };

  DirectoryCell({
    required this.image,
    required this.id,
    required this.dirPath,
    required this.dirName,
  });
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:gallery/src/cell/contentable.dart';
import 'package:gallery/src/cell/data.dart';
import 'package:isar/isar.dart';

import '../cell/cell.dart';

part 'download_file.g.dart';

@collection
class File implements Cell {
  @override
  Id? isarId;

  @Index(unique: true, replace: true)
  final String url;
  @Index(unique: true, replace: true)
  final String name;

  final DateTime date;

  final String site;

  final bool isFailed;

  final bool inProgress;

  bool isOnHold() => isFailed == false && inProgress == false;

  File inprogress() => File(url, true, false, site, name, isarId: isarId);
  File failed() => File(url, false, true, site, name, isarId: isarId);
  File onHold() => File(url, false, false, site, name, isarId: isarId);

  File.d(this.url, this.site, this.name, {this.isarId})
      : inProgress = true,
        isFailed = false,
        date = DateTime.now();

  File(this.url, this.inProgress, this.isFailed, this.site, this.name,
      {this.isarId})
      : date = DateTime.now();

  @override
  @ignore
  List<Widget>? Function(BuildContext context) get addButtons => (_) => null;

  @override
  @ignore
  List<Widget>? Function(
          BuildContext context, dynamic extra, AddInfoColorData colors)
      get addInfo => (_, __, ___) => null;

  @override
  String alias(bool isList) => name;

  @override
  Contentable fileDisplay() {
    throw UnimplementedError();
  }

  @override
  String fileDownloadUrl() {
    throw UnimplementedError();
  }

  @override
  CellData getCellData(bool isList, {BuildContext? context}) =>
      CellData(thumb: null, name: name, stickers: []);
}

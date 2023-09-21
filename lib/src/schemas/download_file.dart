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
import '../db/isar.dart';

part 'download_file.g.dart';

@collection
class DownloadFile implements Cell {
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

  void save() {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.downloadFiles.putSync(this));
  }

  DownloadFile inprogress() =>
      DownloadFile(url, true, false, site, name, isarId: isarId);
  DownloadFile failed() =>
      DownloadFile(url, false, true, site, name, isarId: isarId);
  DownloadFile onHold() =>
      DownloadFile(url, false, false, site, name, isarId: isarId);

  DownloadFile.d(this.url, this.site, this.name, {this.isarId})
      : inProgress = true,
        isFailed = false,
        date = DateTime.now();

  DownloadFile(this.url, this.inProgress, this.isFailed, this.site, this.name,
      {this.isarId})
      : date = DateTime.now();

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  List<Widget>? addInfo(
          BuildContext context, dynamic extra, AddInfoColorData colors) =>
      null;

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

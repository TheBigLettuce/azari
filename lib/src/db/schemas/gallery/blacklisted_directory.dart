// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:isar/isar.dart';

part 'blacklisted_directory.g.dart';

@collection
class BlacklistedDirectory implements Cell {
  BlacklistedDirectory(this.bucketId, this.name);

  @override
  Id? isarId;

  @override
  Key uniqueKey() => ValueKey(bucketId);

  @Index(unique: true, replace: true)
  String bucketId;
  @Index()
  final String name;

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) => null;

  @override
  Widget? contentInfo(BuildContext context) => null;

  @override
  String alias(bool isList) => name;

  @override
  String? fileDownloadUrl() => null;

  @override
  Contentable content() => const EmptyContent();

  @override
  List<Sticker> stickers(BuildContext context) => const [];

  @override
  ImageProvider<Object>? thumbnail() => null;

  static StreamSubscription<void> watch(void Function(void) f,
      [bool fire = true]) {
    return Dbs.g.blacklisted.blacklistedDirectorys
        .watchLazy(fireImmediately: fire)
        .listen(f);
  }

  static void clear() => Dbs.g.blacklisted
      .writeTxnSync(() => Dbs.g.blacklisted.blacklistedDirectorys.clearSync());

  static void deleteAll(List<String> bucketIds) {
    Dbs.g.blacklisted.writeTxnSync(() {
      return Dbs.g.blacklisted.blacklistedDirectorys
          .deleteAllByBucketIdSync(bucketIds);
    });
  }
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:gallery/src/db/initalize_db.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:isar/isar.dart";

part "download_file.g.dart";

@collection
class DownloadFile implements CellBase, Thumbnailable, IsarEntryId {
  DownloadFile(
    this.inProgress,
    this.isFailed, {
    this.isarId,
    required this.name,
    required this.url,
    required this.thumbUrl,
    required this.site,
  }) : date = DateTime.now();
  DownloadFile.d({
    this.isarId,
    required this.name,
    required this.url,
    required this.thumbUrl,
    required this.site,
  })  : inProgress = true,
        isFailed = false,
        date = DateTime.now();

  @override
  Id? isarId;

  @Index(unique: true, replace: true)
  final String url;
  @Index(unique: true, replace: true)
  final String name;

  final String thumbUrl;

  final DateTime date;

  final String site;

  @Index()
  final bool isFailed;

  @Index()
  final bool inProgress;

  @override
  CellStaticData description() => const CellStaticData();

  bool isOnHold() => isFailed == false && inProgress == false;

  void save() {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.downloadFiles.putSync(this));
  }

  DownloadFile inprogress() => DownloadFile(
        true,
        false,
        isarId: isarId,
        url: url,
        thumbUrl: thumbUrl,
        name: name,
        site: site,
      );
  DownloadFile failed() => DownloadFile(
        false,
        true,
        isarId: isarId,
        url: url,
        thumbUrl: thumbUrl,
        name: name,
        site: site,
      );
  DownloadFile onHold() => DownloadFile(
        false,
        false,
        isarId: isarId,
        url: url,
        thumbUrl: thumbUrl,
        name: name,
        site: site,
      );

  @override
  String toString() =>
      "Download${isFailed ? '(failed)' : inProgress ? '(in progress)' : ''}: $name, url: $url";

  @override
  Key uniqueKey() => ValueKey(url);

  @override
  ImageProvider<Object> thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  String alias(bool isList) => name;

  static void saveAll(List<DownloadFile> l) {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.downloadFiles.putAllSync(l));
  }

  static void deleteAll(List<String> urls) {
    Dbs.g.main
        .writeTxnSync(() => Dbs.g.main.downloadFiles.deleteAllByUrlSync(urls));
  }

  static DownloadFile? get(String url) {
    return Dbs.g.main.downloadFiles.getByUrlSync(url);
  }

  static bool exist(String url) {
    return Dbs.g.main.downloadFiles.getByUrlSync(url) != null;
  }

  static List<DownloadFile> get inProgressNow =>
      Dbs.g.main.downloadFiles.where().inProgressEqualTo(true).findAllSync();

  static List<DownloadFile> get allFailed =>
      Dbs.g.main.downloadFiles.where().isFailedEqualTo(true).findAllSync();

  static bool notExist(String url) => !exist(url);

  static void clear() {
    Dbs.g.main.writeTxnSync(() {
      Dbs.g.main.downloadFiles.clearSync();
    });
  }

  static DownloadFile? next() {
    return Dbs.g.main.downloadFiles
        .filter()
        .inProgressEqualTo(false)
        .and()
        .isFailedEqualTo(false)
        .findFirstSync();
  }

  static StreamSubscription<void> watch(
    void Function(void) f, [
    bool fire = true,
  ]) {
    return Dbs.g.main.downloadFiles.watchLazy(fireImmediately: fire).listen(f);
  }

  static List<DownloadFile> nextNumber(int minus) {
    if (Dbs.g.main.downloadFiles.countSync() < 6) {
      return const [];
    }

    return Dbs.g.main.downloadFiles
        .filter()
        .inProgressEqualTo(false)
        .and()
        .isFailedEqualTo(false)
        .sortByDateDesc()
        .limit(6 - minus)
        .findAllSync();
  }
}

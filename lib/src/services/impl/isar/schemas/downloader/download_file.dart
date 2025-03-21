// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/services/impl_table/io.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:isar/isar.dart";

part "download_file.g.dart";

@collection
class IsarDownloadFile extends DownloadFileDataImpl
    implements $DownloadFileData {
  const IsarDownloadFile({
    required this.status,
    required this.name,
    required this.url,
    required this.thumbUrl,
    required this.site,
    required this.date,
    required this.isarId,
  });

  const IsarDownloadFile.noId({
    required this.status,
    required this.name,
    required this.url,
    required this.thumbUrl,
    required this.site,
    required this.date,
  }) : isarId = null;

  final Id? isarId;

  @override
  final DateTime date;

  @override
  @Index(unique: true, replace: true)
  final String name;

  @override
  final String site;

  @override
  @Index()
  @enumerated
  final DownloadStatus status;

  @override
  final String thumbUrl;

  @override
  @Index(unique: true, replace: true)
  final String url;

  @override
  IsarDownloadFile toInProgress() => IsarDownloadFile(
        status: DownloadStatus.inProgress,
        isarId: isarId,
        url: url,
        thumbUrl: thumbUrl,
        name: name,
        site: site,
        date: DateTime.now(),
      );

  @override
  IsarDownloadFile toFailed() => IsarDownloadFile(
        status: DownloadStatus.failed,
        isarId: isarId,
        url: url,
        thumbUrl: thumbUrl,
        name: name,
        site: site,
        date: DateTime.now(),
      );

  @override
  IsarDownloadFile toOnHold() => IsarDownloadFile(
        status: DownloadStatus.onHold,
        isarId: isarId,
        url: url,
        thumbUrl: thumbUrl,
        name: name,
        site: site,
        date: DateTime.now(),
      );
}

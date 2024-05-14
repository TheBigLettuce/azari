// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:isar/isar.dart";

part "download_file.g.dart";

@collection
class IsarDownloadFile extends DownloadFileData implements IsarEntryId {
  IsarDownloadFile({
    required super.status,
    required super.name,
    required super.url,
    required super.thumbUrl,
    required super.site,
    required super.date,
    this.isarId,
  });

  @override
  Id? isarId;

  @override
  DownloadFileData toInProgress() => IsarDownloadFile(
        status: DownloadStatus.inProgress,
        isarId: isarId,
        url: url,
        thumbUrl: thumbUrl,
        name: name,
        site: site,
        date: DateTime.now(),
      );

  @override
  DownloadFileData toFailed() => IsarDownloadFile(
        status: DownloadStatus.failed,
        isarId: isarId,
        url: url,
        thumbUrl: thumbUrl,
        name: name,
        site: site,
        date: DateTime.now(),
      );

  @override
  DownloadFileData toOnHold() => IsarDownloadFile(
        status: DownloadStatus.onHold,
        isarId: isarId,
        url: url,
        thumbUrl: thumbUrl,
        name: name,
        site: site,
        date: DateTime.now(),
      );
}

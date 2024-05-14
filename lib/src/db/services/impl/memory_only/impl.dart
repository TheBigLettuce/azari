// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";

class PlainLocalTagsData extends LocalTagsData {
  const PlainLocalTagsData(super.filename, super.tags);
}

class PlainCompactMangaData extends CompactMangaDataBase with CompactMangaData {
  const PlainCompactMangaData({
    required super.mangaId,
    required super.site,
    required super.thumbUrl,
    required super.title,
  });
}

class PlainSettingsPath extends SettingsPath {
  const PlainSettingsPath(this.path, this.pathDisplay);

  @override
  final String path;

  @override
  final String pathDisplay;
}

class PlainHiddenBooruPostData extends HiddenBooruPostData {
  const PlainHiddenBooruPostData(super.booru, super.postId, super.thumbUrl);
}

class PlainPinnedManga extends CompactMangaDataBase with PinnedManga {
  const PlainPinnedManga({
    required super.mangaId,
    required super.site,
    required super.thumbUrl,
    required super.title,
  });
}

class PlainDownloadFileData extends DownloadFileData {
  const PlainDownloadFileData({
    required super.name,
    required super.url,
    required super.thumbUrl,
    required super.site,
    required super.date,
    required super.status,
  });

  @override
  DownloadFileData toFailed() => PlainDownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.failed,
      );

  @override
  DownloadFileData toInProgress() => PlainDownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.inProgress,
      );

  @override
  DownloadFileData toOnHold() => PlainDownloadFileData(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
        status: DownloadStatus.onHold,
      );
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "download_manager.dart";

class DownloadEntryTags extends DownloadEntry {
  const DownloadEntryTags.d({
    required this.tags,
    required super.name,
    required super.url,
    required super.thumbUrl,
    required super.site,
    super.status,
  }) : super.d();

  final List<String> tags;
}

class DownloadEntry {
  const DownloadEntry._({
    required this.name,
    required this.url,
    required this.thumbUrl,
    required this.site,
    required this.status,
  });

  const DownloadEntry.d({
    required this.name,
    required this.url,
    required this.thumbUrl,
    required this.site,
    this.status = DownloadStatus.inProgress,
  });

  final String name;
  final String url;
  final String thumbUrl;
  final String site;

  final DownloadStatus status;

  DownloadEntry _copyStatus(DownloadStatus newStatus) => DownloadEntry._(
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        status: newStatus,
      );

  DownloadFileData _toDb() => objFactory.makeDownloadFileData(
        status: status,
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: DateTime.now(),
      );
}

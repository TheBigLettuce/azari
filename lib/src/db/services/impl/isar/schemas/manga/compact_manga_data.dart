// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/impl_table/io.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/manga/manga_api.dart";
import "package:isar/isar.dart";

part "compact_manga_data.g.dart";

@collection
class IsarCompactMangaData extends CompactMangaDataImpl
    implements $CompactMangaData {
  const IsarCompactMangaData({
    required this.mangaId,
    required this.site,
    required this.thumbUrl,
    required this.title,
    required this.isarId,
  });

  const IsarCompactMangaData.noId({
    required this.mangaId,
    required this.site,
    required this.thumbUrl,
    required this.title,
  }) : isarId = null;

  final Id? isarId;

  @override
  @Index(unique: true, replace: true, composite: [CompositeIndex("site")])
  final String mangaId;

  @override
  @enumerated
  final MangaMeta site;

  @override
  final String thumbUrl;

  @override
  final String title;
}

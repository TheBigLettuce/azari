// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:isar/isar.dart";

part "saved_manga_chapters.g.dart";

@collection
class IsarSavedMangaChapters extends SavedMangaChaptersData {
  IsarSavedMangaChapters({
    required this.chapters,
    required super.mangaId,
    required super.site,
    required super.page,
  });

  Id? isarId;

  @override
  final List<IsarMangaChapter> chapters;
}

@embedded
final class IsarMangaChapter implements MangaChapter {
  const IsarMangaChapter({
    this.chapter = "",
    this.pages = -1,
    this.title = "",
    this.volume = "",
    this.id = "",
    this.translator = "",
  });

  @override
  final String id;

  @override
  final String title;
  @override
  final String chapter;
  @override
  final String volume;
  @override
  final String translator;

  @override
  final int pages;
}

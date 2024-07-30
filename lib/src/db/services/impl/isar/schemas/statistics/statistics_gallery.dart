// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/services.dart";
import "package:isar/isar.dart";

part "statistics_gallery.g.dart";

@collection
class IsarStatisticsGallery extends StatisticsGalleryData {
  const IsarStatisticsGallery({
    required super.copied,
    required super.deleted,
    required super.joined,
    required super.moved,
    required super.filesSwiped,
    required super.sameFiltered,
    required super.viewedDirectories,
    required super.viewedFiles,
  });

  Id get id => 0;

  @override
  IsarStatisticsGallery add({
    int? viewedDirectories,
    int? viewedFiles,
    int? joined,
    int? filesSwiped,
    int? sameFiltered,
    int? deleted,
    int? copied,
    int? moved,
  }) =>
      IsarStatisticsGallery(
        copied: this.copied + (copied ?? 0),
        deleted: this.deleted + (deleted ?? 0),
        joined: this.joined + (joined ?? 0),
        moved: this.moved + (moved ?? 0),
        filesSwiped: this.filesSwiped + (filesSwiped ?? 0),
        sameFiltered: this.sameFiltered + (sameFiltered ?? 0),
        viewedDirectories: this.viewedDirectories + (viewedDirectories ?? 0),
        viewedFiles: this.viewedFiles + (viewedFiles ?? 0),
      );
}

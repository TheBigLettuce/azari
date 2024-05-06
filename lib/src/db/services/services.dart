// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/base/system_gallery_thumbnail_provider.dart";
import "package:gallery/src/db/services/impl/isar/impl.dart";
import "package:gallery/src/db/services/impl/isar/schemas/downloader/download_file.dart";
import "package:gallery/src/db/services/impl/isar/schemas/settings/settings.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/display_quality.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/cell/contentable.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/net/download_manager/download_manager.dart";
import "package:gallery/src/pages/anime/anime.dart";
import "package:gallery/src/pages/manga/manga_info_page.dart";
import "package:gallery/src/pages/manga/manga_page.dart";
import "package:gallery/src/pages/manga/next_chapter_button.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_masonry_layout.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_quilted.dart";
import "package:gallery/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:isar/isar.dart";

part "settings.dart";
part "saved_anime_characters.dart";
part "saved_anime_entry.dart";
part "video_settings.dart";
part "misc_settings.dart";
part "hidden_booru_post.dart";
part "favorite_post.dart";
part "grid_settings.dart";
part "saved_manga_chapters.dart";
part "read_manga_chapters.dart";
part "pinned_manga.dart";
part "compact_manga_data.dart";
part "chapters_settings.dart";
part "thumbnail.dart";
part "pinned_thumbnail.dart";
part "favorite_file.dart";
part "directory_metadata.dart";
part "blacklisted_directory.dart";
part "statistics_daily.dart";
part "statistics_booru.dart";
part "statistics_gallery.dart";
part "statistics_general.dart";
part "download_file.dart";
part "watched_anime_entry.dart";

ServicesImplTable get _currentDb => ServicesImplTable.isar;
typedef DbConn = ServicesImplTable;

class DatabaseConnectionNotifier extends InheritedWidget {
  const DatabaseConnectionNotifier._({
    super.key,
    required this.db,
    required super.child,
  });

  factory DatabaseConnectionNotifier.current(Widget child) =>
      DatabaseConnectionNotifier._(
        db: _currentDb,
        child: child,
      );

  final DbConn db;

  static DbConn of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<DatabaseConnectionNotifier>();

    return widget!.db;
  }

  @override
  bool updateShouldNotify(DatabaseConnectionNotifier oldWidget) =>
      db != oldWidget.db;
}

enum ServicesImplTable {
  isar;

  SettingsService get settings => switch (this) {
        ServicesImplTable.isar => const IsarSettingsService(),
      };

  MiscSettingsService get miscSettings => switch (this) {
        ServicesImplTable.isar => const IsarMiscSettingsService(),
      };

  SavedAnimeEntriesService get savedAnimeEntries => switch (this) {
        ServicesImplTable.isar => const IsarSavedAnimeEntriesService(),
      };

  SavedAnimeCharactersService get savedAnimeCharacters => switch (this) {
        ServicesImplTable.isar => const IsarSavedAnimeCharatersService(),
      };

  WatchedAnimeEntryService get watchedAnime => switch (this) {
        ServicesImplTable.isar => const IsarWatchedAnimeEntryService(),
      };

  VideoSettingsService get videoSettings => switch (this) {
        ServicesImplTable.isar => const IsarVideoService(),
      };

  HiddenBooruPostService get hiddenBooruPost => switch (this) {
        ServicesImplTable.isar => const IsarHiddenBooruPostService(),
      };

  DownloadFileService get downloads => switch (this) {
        ServicesImplTable.isar => const IsarDownloadFileService(),
      };

  FavoritePostService get favoritePosts => switch (this) {
        ServicesImplTable.isar => const IsarFavoritePostService(),
      };

  StatisticsGeneralService get statisticsGeneral => switch (this) {
        ServicesImplTable.isar => const IsarStatisticsGeneralService(),
      };

  StatisticsGalleryService get statisticsGallery => switch (this) {
        ServicesImplTable.isar => const IsarStatisticsGalleryService(),
      };

  StatisticsBooruService get statisticsBooru => switch (this) {
        ServicesImplTable.isar => const IsarStatisticsBooruService(),
      };

  StatisticsDailyService get statisticsDaily => switch (this) {
        ServicesImplTable.isar => const IsarDailyStatisticsService(),
      };

  DirectoryMetadataService get directoryMetadata => switch (this) {
        ServicesImplTable.isar => const IsarDirectoryMetadataService(),
      };

  ChaptersSettingsService get chaptersSettings => switch (this) {
        ServicesImplTable.isar => const IsarChapterSettingsService(),
      };

  SavedMangaChaptersService get savedMangaChapters => switch (this) {
        ServicesImplTable.isar => const IsarSavedMangaChaptersService(),
      };

  ReadMangaChaptersService get readMangaChapters => switch (this) {
        ServicesImplTable.isar => const IsarReadMangaChapterService(),
      };

  PinnedMangaService get pinnedManga => switch (this) {
        ServicesImplTable.isar => const IsarPinnedMangaService(),
      };
}

abstract interface class ServiceMarker {}

mixin DbConnHandle<T extends ServiceMarker> implements StatefulWidget {
  T get db;
}

mixin DbScope<T extends ServiceMarker, W extends DbConnHandle<T>> on State<W> {}

abstract interface class ResourceSource<T> {
  T? forIdx(int idx);
  T forIdxUnsafe(int idx);

  Future<int> clearRefresh();

  Future<int> next();

  void destroy();
}

abstract interface class LocalTagDictionaryService {
  void addAll(List<String> tags);
}

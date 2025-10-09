// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class GridSettingsService implements ServiceMarker {
  const GridSettingsService();

  static bool get available => _dbInstance.get<GridSettingsService>() != null;

  GridSettingsData<BooruData> get booru;
  GridSettingsData<DirectoriesData> get directories;
  GridSettingsData<FavoritePostsData> get favoritePosts;
  GridSettingsData<FilesData> get files;
}

sealed class GridSettingsType {
  const GridSettingsType();
}

abstract class FilesData implements GridSettingsType {
  const FilesData();
}

abstract class FavoritePostsData implements GridSettingsType {
  const FavoritePostsData();
}

abstract class DirectoriesData implements GridSettingsType {
  const DirectoriesData();
}

abstract class BooruData implements GridSettingsType {
  const BooruData();
}

abstract class GridSettingsData<T extends GridSettingsType>
    implements ServiceMarker {
  factory GridSettingsData() => _dbInstance.get<GridSettingsData<T>>()!;

  static GridSettingsData<T>? safe<T extends GridSettingsType>() =>
      _dbInstance.get<GridSettingsData<T>>();

  ShellConfigurationData get current;
  set current(ShellConfigurationData d);

  StreamSubscription<ShellConfigurationData> watch(
    void Function(ShellConfigurationData) f, [
    bool fire = false,
  ]);
}

enum GridLayoutType {
  grid(),
  list(),
  gridQuilted();

  const GridLayoutType();

  String translatedString(AppLocalizations l10n) => switch (this) {
    GridLayoutType.grid => l10n.enumGridLayoutTypeGrid,
    GridLayoutType.list => l10n.enumGridLayoutTypeList,
    GridLayoutType.gridQuilted => l10n.enumGridLayoutTypeGridQuilted,
  };
}

@immutable
abstract class ShellConfigurationData {
  const ShellConfigurationData();

  bool get hideName;
  GridAspectRatio get aspectRatio;
  GridColumn get columns;
  GridLayoutType get layoutType;

  ShellConfigurationData copy({
    bool? hideName,
    GridAspectRatio? aspectRatio,
    GridColumn? columns,
    GridLayoutType? layoutType,
  });
}

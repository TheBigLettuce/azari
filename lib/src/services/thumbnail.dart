// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

// TODO: merge PlatformApi.thumbs
mixin class ThumbnailService implements ServiceMarker {
  const ThumbnailService();

  static bool get available => _instance != null;
  static ThumbnailService? safe() => _instance;

  // ignore: unnecessary_late
  static late final _instance = _dbInstance.get<ThumbnailService>();

  void clear() => _instance!.clear();

  ThumbnailData? get(int id) => _instance!.get(id);

  void delete(int id) => _instance!.delete(id);

  void addAll(List<ThumbId> l) => _instance!.addAll(l);
}

@immutable
abstract class ThumbnailData {
  const ThumbnailData();

  int get id;
  String get path;
  int get differenceHash;
  DateTime get updatedAt;
}

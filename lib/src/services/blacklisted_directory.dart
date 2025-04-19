// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

mixin class BlacklistedDirectoryService
    implements ResourceSource<String, BlacklistedDirectoryData>, ServiceMarker {
  const BlacklistedDirectoryService();

  static bool get available => _instance != null;
  static BlacklistedDirectoryService? safe() => _instance;

  // ignore: unnecessary_late
  static late final _instance = _dbInstance.get<BlacklistedDirectoryService>();

  List<BlacklistedDirectoryData> getAll(List<String> bucketIds) =>
      _instance!.getAll(bucketIds);

  @override
  SourceStorage<String, BlacklistedDirectoryData> get backingStorage =>
      _instance!.backingStorage;

  @override
  Future<int> clearRefresh() => _instance!.clearRefresh();

  @override
  void destroy() => _instance!.destroy();

  @override
  bool get hasNext => _instance!.hasNext;

  @override
  Future<int> next() => _instance!.next();

  @override
  RefreshingProgress get progress => _instance!.progress;
}

@immutable
abstract class BlacklistedDirectoryData
    with DefaultBuildCell
    implements BlacklistedDirectoryDataBase, BlacklistedDirectoryDataImpl {
  const factory BlacklistedDirectoryData({
    required String bucketId,
    required String name,
  }) = $BlacklistedDirectoryData;
}

abstract class BlacklistedDirectoryDataBase {
  String get bucketId;
  String get name;
}

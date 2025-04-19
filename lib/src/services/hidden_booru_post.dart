// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension HiddenBooruPostServiceExt on HiddenBooruPostsService {
  bool isHidden(int id, Booru booru) => cachedValues.containsKey((id, booru));
}

mixin class HiddenBooruPostsService implements ServiceMarker {
  const HiddenBooruPostsService();

  static bool get available => _instance != null;
  static HiddenBooruPostsService? safe() => _instance;

  // ignore: unnecessary_late
  static late final _instance = _dbInstance.get<HiddenBooruPostsService>();

  Map<(int, Booru), String> get cachedValues => _instance!.cachedValues;

  void addAll(List<HiddenBooruPostData> booru) => _instance!.addAll(booru);
  void removeAll(List<(int, Booru)> booru) => _instance!.removeAll(booru);

  StreamSubscription<int> watch(
    void Function(int) f, [
    bool fire = false,
  ]) =>
      _instance!.watch(f, fire);

  Stream<bool> streamSingle(int id, Booru booru, [bool fire = false]) =>
      _instance!.streamSingle(id, booru, fire);
}

@immutable
abstract class HiddenBooruPostData
    with DefaultBuildCell
    implements CellBuilder {
  const factory HiddenBooruPostData({
    required Booru booru,
    required int postId,
    required String thumbUrl,
  }) = $HiddenBooruPostData;

  String get thumbUrl;
  int get postId;
  Booru get booru;
}

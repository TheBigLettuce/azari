// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension HiddenBooruPostServiceExt on HiddenBooruPostsService {
  bool isHidden(int id, Booru booru) => cachedValues.containsKey((id, booru));
}

abstract interface class HiddenBooruPostsService implements ServiceMarker {
  Map<(int, Booru), String> get cachedValues;

  void addAll(List<HiddenBooruPostData> booru);
  void removeAll(List<(int, Booru)> booru);

  StreamSubscription<void> watch(void Function(void) f);
  Stream<bool> streamSingle(int id, Booru booru, [bool fire = false]);
}

@immutable
abstract class HiddenBooruPostData implements CellBase, Thumbnailable {
  const factory HiddenBooruPostData({
    required Booru booru,
    required int postId,
    required String thumbUrl,
  }) = $HiddenBooruPostData;

  String get thumbUrl;
  int get postId;
  Booru get booru;
}

@immutable
abstract class HiddenBooruPostDataImpl
    with DefaultBuildCellImpl
    implements HiddenBooruPostData {
  const HiddenBooruPostDataImpl();

  @override
  ImageProvider<Object> thumbnail(BuildContext? context) =>
      CachedNetworkImageProvider(thumbUrl);

  @override
  Key uniqueKey() => ValueKey((postId, booru));

  @override
  String alias(bool isList) => "$postId";

  @override
  CellStaticData description() => const CellStaticData();
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class FavoritePostSourceService
    implements
        ResourceSource<(int id, Booru booru), FavoritePost>,
        ServiceMarker {
  List<PostBase> addRemove(List<PostBase> posts);

  bool isFavorite(int id, Booru booru);
  bool contains(int id, Booru booru);

  StreamSubscription<T> watchSingle<T>(
    int id,
    Booru booru,
    T Function(bool) transform,
    void Function(T) f, [
    bool fire = false,
  ]);

  Stream<bool> streamSingle(int postId, Booru booru, [bool fire = false]);
}

@immutable
abstract class FavoritePost
    implements PostBase, PostImpl, Pressable<FavoritePost> {
  const factory FavoritePost({
    required int id,
    required String md5,
    required List<String> tags,
    required int width,
    required int height,
    required String fileUrl,
    required String previewUrl,
    required String sampleUrl,
    required String sourceUrl,
    required PostRating rating,
    required int score,
    required DateTime createdAt,
    required Booru booru,
    required PostContentType type,
    required int size,
  }) = $FavoritePost;

  @override
  CellStaticData description() => const CellStaticData();

  @override
  String toString() => "FavoritePostData: $id";
}

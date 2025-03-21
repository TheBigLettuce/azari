// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension FavoritePostSaveExt on FavoritePost {
  void maybeSave() {
    _currentDb.get<FavoritePostSourceService>()?.addAll([
      this,
    ]);
  }
}

abstract interface class FavoritePostSourceService implements ServiceMarker {
  FavoritePostCache get cache;

  void addAll(List<FavoritePost> posts);
  void removeAll(List<(int id, Booru booru)> idxs);

  void addRemove(List<PostBase> posts);
}

abstract class FavoritePostCache
    extends ReadOnlyStorage<(int, Booru), FavoritePost> {
  bool isFavorite(int id, Booru booru);

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
    required FavoriteStars stars,
  }) = $FavoritePost;

  FavoriteStars get stars;

  @override
  CellStaticData description() => const CellStaticData();

  @override
  String toString() => "FavoritePostData: $id";

  FavoritePost copyWith({
    int? id,
    String? md5,
    List<String>? tags,
    int? width,
    int? height,
    String? fileUrl,
    String? previewUrl,
    String? sampleUrl,
    String? sourceUrl,
    PostRating? rating,
    int? score,
    DateTime? createdAt,
    Booru? booru,
    PostContentType? type,
    int? size,
    FavoriteStars? stars,
  });
}

mixin FavoritePostCopyMixin implements FavoritePost {
  @override
  FavoritePost copyWith({
    int? id,
    String? md5,
    List<String>? tags,
    int? width,
    int? height,
    String? fileUrl,
    String? previewUrl,
    String? sampleUrl,
    String? sourceUrl,
    PostRating? rating,
    int? score,
    DateTime? createdAt,
    Booru? booru,
    PostContentType? type,
    int? size,
    FavoriteStars? stars,
  }) =>
      FavoritePost(
        id: id ?? this.id,
        md5: md5 ?? this.md5,
        tags: tags ?? this.tags,
        width: width ?? this.width,
        height: height ?? this.height,
        fileUrl: fileUrl ?? this.fileUrl,
        previewUrl: previewUrl ?? this.previewUrl,
        sampleUrl: sampleUrl ?? this.sampleUrl,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        rating: rating ?? this.rating,
        score: score ?? this.score,
        createdAt: createdAt ?? this.createdAt,
        booru: booru ?? this.booru,
        type: type ?? this.type,
        size: size ?? this.size,
        stars: stars ?? this.stars,
      );
}

enum FavoriteStars {
  zero,
  zeroFive,
  one,
  oneFive,
  two,
  twoFive,
  three,
  threeFive,
  four,
  fourFive,
  five;

  bool get isHalf => switch (this) {
        FavoriteStars.zero => false,
        FavoriteStars.zeroFive => true,
        FavoriteStars.one => false,
        FavoriteStars.oneFive => true,
        FavoriteStars.two => false,
        FavoriteStars.twoFive => true,
        FavoriteStars.three => false,
        FavoriteStars.threeFive => true,
        FavoriteStars.four => false,
        FavoriteStars.fourFive => true,
        FavoriteStars.five => false,
      };

  bool includes(FavoriteStars other) {
    return index >= other.index;
  }

  double get asNumber => switch (this) {
        FavoriteStars.zero => 0,
        FavoriteStars.zeroFive => 0.5,
        FavoriteStars.one => 1,
        FavoriteStars.oneFive => 1.5,
        FavoriteStars.two => 2,
        FavoriteStars.twoFive => 2.5,
        FavoriteStars.three => 3,
        FavoriteStars.threeFive => 3.5,
        FavoriteStars.four => 4,
        FavoriteStars.fourFive => 4.5,
        FavoriteStars.five => 5,
      };

  String translatedString(BuildContext context) => switch (this) {
        FavoriteStars.zero => "5 stars", // TODO: change
        FavoriteStars.zeroFive => "4.5 stars",
        FavoriteStars.one => "4 stars",
        FavoriteStars.oneFive => "3.5 stars",
        FavoriteStars.two => "3 stars",
        FavoriteStars.twoFive => "2.5 stars",
        FavoriteStars.three => "2 stars",
        FavoriteStars.threeFive => "1.5 stars",
        FavoriteStars.four => "1 star",
        FavoriteStars.fourFive => "0.5 star",
        FavoriteStars.five => "No stars",
      };
}

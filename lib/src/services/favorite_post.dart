// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension FavoritePostSaveExt on FavoritePost {
  void maybeSave() {
    _dbInstance.get<FavoritePostSourceService>()?.addAll([
      this,
    ]);
  }
}

mixin class FavoritePostSourceService implements ServiceMarker {
  const FavoritePostSourceService();

  static bool get available => _instance != null;
  static FavoritePostSourceService? safe() => _instance;

  // ignore: unnecessary_late
  static late final _instance = _dbInstance.get<FavoritePostSourceService>();

  FavoritePostCache get cache => _instance!.cache;

  void addAll(List<FavoritePost> posts) => _instance!.addAll(posts);

  void removeAll(List<(int id, Booru booru)> idxs) =>
      _instance!.removeAll(idxs);

  void addRemove(List<PostBase> posts) => _instance!.addRemove(posts);
}

abstract class FavoritePostCache
    extends ReadOnlyStorage<(int, Booru), FavoritePost> {
  bool isFavorite(int id, Booru booru);

  Stream<bool> streamSingle(int postId, Booru booru, [bool fire = false]);
}

mixin FavoritePostsWatcherMixin<S extends StatefulWidget> on State<S> {
  StreamSubscription<int>? _favoritePostsEvents;

  void onFavoritePostsUpdate() {}

  @override
  void initState() {
    super.initState();

    const favoritePosts = FavoritePostSourceService();

    _favoritePostsEvents?.cancel();
    _favoritePostsEvents = favoritePosts.cache.watch((_) {
      // final oldSettings = settings;
      // settings = newSettings;

      onFavoritePostsUpdate();

      setState(() {});
    });
  }

  @override
  void dispose() {
    _favoritePostsEvents?.cancel();

    super.dispose();
  }
}

@immutable
abstract class FavoritePost implements PostBase, PostImpl {
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
    required FilteringColors filteringColors,
  }) = $FavoritePost;

  FavoriteStars get stars;
  FilteringColors get filteringColors;

  @override
  String toString() => "FavoritePost: $id";

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
    FilteringColors? filteringColors,
  });

  FavoritePost applyBase(PostBase post);
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
    FilteringColors? filteringColors,
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
        filteringColors: filteringColors ?? this.filteringColors,
      );

  @override
  FavoritePost applyBase(PostBase post) => FavoritePost(
        id: post.id,
        md5: post.md5,
        tags: post.tags,
        width: post.width,
        height: post.height,
        fileUrl: post.fileUrl,
        previewUrl: post.previewUrl,
        sampleUrl: post.sampleUrl,
        sourceUrl: post.sourceUrl,
        rating: post.rating,
        score: post.score,
        createdAt: post.createdAt,
        booru: post.booru,
        type: post.type,
        size: post.size,
        stars: stars,
        filteringColors: filteringColors,
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

  String translatedString(AppLocalizations l10n) => switch (this) {
        FavoriteStars.zero => l10n.stars(0),
        FavoriteStars.zeroFive => l10n.stars(0.5),
        FavoriteStars.one => l10n.stars(1),
        FavoriteStars.oneFive => l10n.stars(1.5),
        FavoriteStars.two => l10n.stars(2),
        FavoriteStars.twoFive => l10n.stars(2.5),
        FavoriteStars.three => l10n.stars(3),
        FavoriteStars.threeFive => l10n.stars(3.5),
        FavoriteStars.four => l10n.stars(4),
        FavoriteStars.fourFive => l10n.stars(4.5),
        FavoriteStars.five => l10n.stars(5),
      };
}

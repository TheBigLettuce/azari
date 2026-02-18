// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/impl/danbooru.dart";
import "package:azari/src/logic/net/booru/impl/gelbooru.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";

int refreshPostCountLimit() => 100;

/// The interface to interact with the various booru APIs.
///
/// Implementations of this interface should hold no state, other than the internal
/// network client(like Dio).
/// If the booru API doesn't support getting posts down a certain post number,
/// the implementation should use [PageSaver] to save and retreive the page,
/// and always return true when accessing [wouldBecomeStale] property.
abstract class BooruAPI {
  const BooruAPI();

  /// Total posts on the booru.
  Future<int> totalPosts(String tags, SafeMode safeMode);

  /// Some booru do not support pulling posts down a certain post number.
  /// This makes the data stale after a time, requiring more refreshes.
  /// This flag exists to optimize paging-based implementations, for example,
  /// refreshing when the saved booru post data is too old.
  bool get wouldBecomeStale;

  /// Booru enum of this API. All the supported boorus should be added to this enum.
  Booru get booru;

  Map<String, String> get loginAndKey;

  /// Get a single post by it's id.
  Future<Post> singlePost(int id);

  /// Load random 30 posts.
  Future<List<Post>> randomPosts(
    SafeMode safeMode,
    bool videosOnly, {
    RandomPostsOrder order = RandomPostsOrder.random,
    String addTags = "",
    int page = 0,
  });

  /// Get posts by a certain page.
  Future<(List<Post>, int?)> page(
    int p,
    String tags,
    SafeMode safeMode, {
    int? limit,
    BooruPostsOrder order = BooruPostsOrder.latest,
    required PageSaver pageSaver,
  });

  /// Get the post's notes.
  /// Usually used for translations.
  Future<Iterable<String>> notes(int postId);

  /// Get posts down a certain post number.
  Future<(List<Post>, int?)> fromPostId(
    int postId,
    String tags,
    SafeMode safeMode, {
    int? limit,
    BooruPostsOrder order = BooruPostsOrder.latest,
    required PageSaver pageSaver,
  });

  Future<List<TagData>> searchTag(
    String tag, [
    BooruTagSorting sorting = BooruTagSorting.count,
    int limit = 30,
  ]);

  Future<void> cancelRequests();

  void destroy();

  /// Additional tag filters.
  static Map<String, void> get additionalSafetyTags => const {
    "guro": null,
    "loli": null,
    "shota": null,
    "bestiality": null,
    "gore": null,
    "ryona": null,
    "scat": null,
  };

  /// [fromSettings] returns a selected booru API from the DB.
  /// Some booru have no way to retreive posts down a certain post number,
  /// in such a case the implementation is likely to use paging,
  /// and should use provided [pageSaver] for this purpose.
  static BooruAPI fromSettings(SettingsService settingsService) {
    return BooruAPI.fromEnum(settingsService.current.selectedBooru);
  }

  /// Sometimes, it is needed to constuct [BooruAPI] instance which isn't the
  /// current selected/used one.
  static BooruAPI fromEnum(Booru booru) {
    final Dio dio = Dio();
    final token = CancelToken();

    return switch (booru) {
      Booru.danbooru => Danbooru(dio, token),
      Booru.gelbooru => Gelbooru(dio, token),
    };
  }

  static Map<String, String> imageHeaders(Booru booru) => switch (booru) {
    Booru.gelbooru => const {"Referer": "https://gelbooru.com/"},
    Booru.danbooru => const {},
  };

  static Map<String, String> credentials(Booru booru) {
    final data = const AccountsService().current;

    switch (booru) {
      case Booru.danbooru:
        if (data.danbooruApiKey.isEmpty && data.danbooruUsername.isEmpty) {
          return const {};
        }

        return {"login": data.danbooruUsername, "api_key": data.danbooruApiKey};
      case Booru.gelbooru:
        {
          if (data.gelbooruApiKey.isEmpty && data.gelbooruUserId.isEmpty) {
            return const {};
          }

          return {
            "api_key": data.gelbooruApiKey,
            "user_id": data.gelbooruUserId,
          };
        }
    }
  }
}

abstract interface class BooruCommunityAPI {
  Booru get booru;

  static BooruCommunityAPI? fromEnum(Booru booru) => switch (booru) {
    Booru.gelbooru => null,
    Booru.danbooru => DanbooruCommunity(booru: booru, client: Dio()),
  };

  static bool supported(Booru booru) => switch (booru) {
    Booru.gelbooru => false,
    Booru.danbooru => true,
  };

  BooruCommentsAPI get comments;
  BooruPoolsAPI get pools;

  BooruForumAPI get forum;
  // BooruWikiAPI get wiki;
  BooruArtistsAPI get artists;

  Future<void> cancelRequests();

  void destroy();
}

abstract interface class BooruWikiAPI {
  Future<List<BooruForumTopic>> search({
    int? limit,
    String? title,
    BooruForumCategory? category,
    BooruForumTopicsOrder order = BooruForumTopicsOrder.postCount,
    required PageSaver pageSaver,
  });
}

abstract interface class BooruForumAPI {
  Future<List<BooruForumTopic>> searchTopic({
    int? limit,
    String? title,
    BooruForumCategory? category,
    BooruForumTopicsOrder order = BooruForumTopicsOrder.postCount,
    required PageSaver pageSaver,
  });

  Future<List<BooruForumPost>> postsForId({
    required int id,
    int? limit,
    BooruForumCategory? category,
    required PageSaver pageSaver,
  });
}

abstract class BooruForumPost {
  bool get isDeleted;

  int get id;
  int get topicId;

  String get body;

  DateTime get updatedAt;
}

abstract class BooruForumTopic {
  bool get isDeleted;
  bool get isSticky;
  bool get isLocked;

  int get id;
  int get creatorId;

  int get postsCount;

  String get title;

  BooruUserLevel get userLevel;
  BooruForumCategory get category;

  DateTime get updatedAt;
}

enum BooruForumTopicsOrder { sticky, postCount }

enum BooruForumCategory { general, tags, bugs }

enum BooruUserLevel {
  restricted,
  member,
  premium,
  janitor,
  contributor,
  approver,
  moderator,
  admin,
}

abstract interface class BooruArtistsAPI {
  Future<List<BooruArtist>> search({
    required int page,
    int limit = 30,
    String? name,
    String? otherName,
    BooruArtistsOrder order = BooruArtistsOrder.postCount,
    required PageSaver pageSaver,
  });
}

abstract class BooruArtist implements CellBuilder {
  bool get isBanned;
  bool get isDeleted;

  int get id;

  String get name;
  String get groupName;

  List<String> get otherNames;

  DateTime get updatedAt;
}

abstract class BooruArtistImpl
    with DefaultBuildCell, CellBuilderData
    implements CellBuilder, BooruArtist {
  const BooruArtistImpl();

  @override
  Key uniqueKey() => ValueKey(id);

  @override
  String title(AppLocalizations l10n) => name;
}

enum BooruArtistsOrder { name, latest, postCount }

abstract interface class BooruPoolsAPI {
  Booru get booru;

  Future<int> postsCount(BooruPool pool);

  Future<BooruPool> single(BooruPool pool);

  Future<List<BooruPool>> search({
    required int page,
    int limit = 30,
    String? name,
    BooruPoolCategory? category,
    BooruPoolsOrder order = BooruPoolsOrder.latest,
    required PageSaver pageSaver,
  });

  Future<List<Post>> posts({
    required int page,
    required BooruPool pool,
    required PageSaver pageSaver,
  });
}

enum BooruPoolsOrder {
  name,
  latest,
  creationTime,
  postCount;

  String translatedString(AppLocalizations l10n) => switch (this) {
    BooruPoolsOrder.name => l10n.enumBooruPoolsOrderName,
    BooruPoolsOrder.latest => l10n.enumBooruPoolsOrderLatest,
    BooruPoolsOrder.creationTime => l10n.enumBooruPoolsOrderCreationTime,
    BooruPoolsOrder.postCount => l10n.enumBooruPoolsOrderPostCount,
  };

  IconData icon() => switch (this) {
    BooruPoolsOrder.name => Icons.sort_by_alpha_rounded,
    BooruPoolsOrder.latest => Icons.new_releases_rounded,
    BooruPoolsOrder.creationTime => Icons.access_time_rounded,
    BooruPoolsOrder.postCount => Icons.onetwothree_rounded,
  };
}

enum BooruPoolCategory {
  series,
  collection;

  String translatedString(AppLocalizations l10n) => switch (this) {
    BooruPoolCategory.series => l10n.enumBooruPoolCategorySeries,
    BooruPoolCategory.collection => l10n.enumBooruPoolCategoryCollection,
  };
}

abstract interface class BooruCommentsAPI {
  Future<List<BooruComments>> search({
    int? limit,
    // required int offset,
    BooruCommentsOrder order = BooruCommentsOrder.latest,
    required PageSaver pageSaver,
  });

  Future<List<BooruComments>> forPostId({
    required int postId,
    int? limit,
    required PageSaver pageSaver,
  });
}

enum BooruCommentsOrder { latest, score }

abstract class BooruComments {
  bool get isSticky;

  int get id;
  int get postId;

  int get score;

  String get body;

  DateTime get updatedAt;
}

enum RandomPostsOrder { random, latest, rating }

enum BooruTagSorting { similarity, count }

enum BooruPostsOrder { latest, score }

/// Paging helper for [BooruAPI] implementations.
/// This class expects a some kind of persistence of it's implementors,
/// if no persistence is needed use [PageSaver.noPersist].
abstract class PageSaver {
  const PageSaver();

  factory PageSaver.noPersist() = _EmptyPageSaver;

  int get page;
  set page(int p);
}

class _EmptyPageSaver implements PageSaver {
  _EmptyPageSaver();

  @override
  int page = 0;
}

enum SafeMode {
  normal,
  relaxed,
  none,
  explicit;

  const SafeMode();

  bool inLevel(SafeMode to) => switch (this) {
    SafeMode.normal => to == normal,
    SafeMode.none => to == none || to == relaxed || to == normal,
    SafeMode.relaxed => to == normal || to == relaxed,
    SafeMode.explicit => to == explicit,
  };

  bool inLevelPostRating(PostRating rating) => switch (this) {
    SafeMode.normal => rating == PostRating.general,
    SafeMode.relaxed =>
      rating == PostRating.sensitive || rating == PostRating.general,
    SafeMode.explicit =>
      rating == PostRating.questionable || rating == PostRating.explicit,
    SafeMode.none => true,
  };

  String translatedString(AppLocalizations l10n) => switch (this) {
    SafeMode.normal => l10n.enumSafeModeNormal,
    SafeMode.none => l10n.enumSafeModeNone,
    SafeMode.relaxed => l10n.enumSafeModeRelaxed,
    SafeMode.explicit => l10n.enumSafeModeExplicit,
  };

  IconData icon() => switch (this) {
    SafeMode.normal => Icons.no_adult_content_outlined,
    SafeMode.relaxed => Icons.visibility_outlined,
    SafeMode.none => Icons.explicit_outlined,
    SafeMode.explicit => Icons.eighteen_up_rating_outlined,
  };
}

enum DisplayQuality {
  original,
  sample;

  const DisplayQuality();

  String translatedString(AppLocalizations l10n) => switch (this) {
    DisplayQuality.original => l10n.enumDisplayQualityOriginal,
    DisplayQuality.sample => l10n.enumDisplayQualitySample,
  };
}

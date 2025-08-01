// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/impl/danbooru.dart";
import "package:azari/src/logic/net/booru/impl/gelbooru.dart";
import "package:azari/src/services/services.dart";
import "package:dio/dio.dart";

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
  static BooruAPI fromSettings(SettingsService settingsService, Dio client) {
    return BooruAPI.fromEnum(settingsService.current.selectedBooru, client);
  }

  /// Constructs a default Dio client instance for [BooruAPI].
  static Dio defaultClientForBooru(Booru booru) {
    final Dio dio = Dio();

    return dio;
  }

  /// Sometimes, it is needed to constuct [BooruAPI] instance which isn't the
  /// current selected/used one.
  static BooruAPI fromEnum(Booru booru, Dio client) {
    return switch (booru) {
      Booru.danbooru => Danbooru(client),
      Booru.gelbooru => Gelbooru(client),
    };
  }
}

abstract interface class BooruCommunityAPI {
  Booru get booru;

  static BooruCommunityAPI? fromEnum(Booru booru, Dio client) =>
      switch (booru) {
        Booru.gelbooru => null,
        Booru.danbooru => DanbooruCommunity(booru: booru, client: client),
      };

  static bool supported(Booru booru) => switch (booru) {
    Booru.gelbooru => false,
    Booru.danbooru => true,
  };

  BooruCommentsAPI get comments;
  BooruPoolsAPI get pools;

  BooruForumAPI get forum;
  // BooruWikiAPI get wiki;
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
    int? limit,
    String? otherName,
    String? name,
    BooruArtistsOrder order = BooruArtistsOrder.postCount,
    required PageSaver pageSaver,
  });
}

abstract class BooruArtist {
  bool get isBanned;
  bool get isDeleted;

  int get id;

  String get name;
  String get groupName;

  List<String> get otherNames;

  DateTime get updatedAt;
}

enum BooruArtistsOrder { name, latest, postCount }

abstract interface class BooruPoolsAPI {
  Future<List<BooruPool>> search({
    int? limit,
    String? name,
    BooruPoolCategory? category,
    BooruPoolsOrder order = BooruPoolsOrder.creationTime,
    required PageSaver pageSaver,
  });

  Future<Map<int, String>> poolThumbnails(List<BooruPool> pools);
}

abstract class BooruPool {
  bool get isDeleted;

  int get id;

  String get name;
  String get description;

  List<int> get postIds;

  BooruPoolCategory get category;

  DateTime get updatedAt;
}

enum BooruPoolsOrder { name, latest, creationTime, postCount }

enum BooruPoolCategory { series, collection }

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

  String translatedString(AppLocalizations l10n) => switch (this) {
    SafeMode.normal => l10n.enumSafeModeNormal,
    SafeMode.none => l10n.enumSafeModeNone,
    SafeMode.relaxed => l10n.enumSafeModeRelaxed,
    SafeMode.explicit => l10n.enumSafeModeExplicit,
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

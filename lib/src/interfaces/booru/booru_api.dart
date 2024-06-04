// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:dio/dio.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/net/booru/danbooru.dart";
import "package:gallery/src/net/booru/gelbooru.dart";

/// The interface to interact with the various booru APIs.
///
/// Implementations of this interface should hold no state, other than the internal
/// network client(like Dio).
/// If the booru API doesn't support getting posts down a certain post number,
/// the implementation should use [PageSaver] to save and retreive the page,
/// and always return true when accessing [wouldBecomeStale] property.
abstract class BooruAPI {
  const BooruAPI();

  /// Some booru do not support pulling posts down a certain post number.
  /// This makes the data stale after a time, requiring more refreshes.
  /// This flag exists to optimize paging-based implementations, for example,
  /// refreshing when the saved booru post data is too old.
  bool get wouldBecomeStale;

  /// Booru enum of this API. All the supported boorus should be added to this enum.
  Booru get booru;

  /// Get a single post by it's id.
  Future<Post> singlePost(int id);

  /// Get posts by a certain page.
  /// This is only used to refresh the grid,
  /// the code which loads and presets the posts uses [fromPost] for further posts loading.
  Future<(List<Post>, int?)> page(
    int p,
    String tags,
    BooruTagging excludedTags,
    SafeMode safeMode,
  );

  /// Get the post's notes.
  /// Usually used for translations.
  Future<Iterable<String>> notes(int postId);

  /// Get posts down a certain post number.
  Future<(List<Post>, int?)> fromPost(
    int postId,
    String tags,
    BooruTagging excludedTags,
    SafeMode safeMode,
  );

  /// Tag completition, this shouldn't present more than 10 at a time.
  Future<List<BooruTag>> completeTag(String tag);

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
  static BooruAPI fromSettings(Dio client, PageSaver pageSaver) {
    return BooruAPI.fromEnum(
      SettingsService.db().current.selectedBooru,
      client,
      pageSaver,
    );
  }

  /// Constructs a default Dio client instance for [BooruAPI].
  static Dio defaultClientForBooru(Booru booru) {
    final Dio dio = Dio();

    return dio;
  }

  /// Sometimes, it is needed to constuct [BooruAPI] instance which isn't the
  /// current selected/used one.
  static BooruAPI fromEnum(Booru booru, Dio client, PageSaver pageSaver) {
    return switch (booru) {
      Booru.danbooru => Danbooru(client),
      Booru.gelbooru => Gelbooru(client, pageSaver),
    };
  }
}

class BooruTag {
  const BooruTag(this.tag, this.count);

  final String tag;
  final int count;
}

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

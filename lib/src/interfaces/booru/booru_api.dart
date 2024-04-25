// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:dio/dio.dart";
import "package:dio_cookie_manager/dio_cookie_manager.dart";
import "package:gallery/src/db/schemas/booru/post.dart";
import "package:gallery/src/db/schemas/grid_settings/booru.dart";
import "package:gallery/src/db/services/settings.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/booru_tagging.dart";
import "package:gallery/src/net/booru/danbooru.dart";
import "package:gallery/src/net/booru/gelbooru.dart";
import "package:gallery/src/net/cookie_jar_tab.dart";
import "package:gallery/src/net/unsaveable_cookie_jar.dart";

/// The interface to interact with the various booru APIs.
///
/// Implemenations of this interface should hold no state, other than the [client].
/// In case when booru API doesn't support getting posts down a certain post number,
/// it should keep the page number and increase it after calls to [fromPost],
/// return the current page in [currentPage], return true in [wouldBecomeStale]
/// and reset page number after calls to [page].
abstract class BooruAPI {
  const BooruAPI();

  /// Some booru do not support pulling posts down a certain post number,
  /// this flag reflects this.
  bool get wouldBecomeStale;

  /// Booru enum of this API. All the boorus should be added to this enum.
  Booru get booru;

  /// Get a single post by it's id.
  /// This is used in many places, like tags and single post loading in the "Tags" page.
  Future<Post> singlePost(int id);

  /// Get posts by a certain page.
  /// This is only used to refresh the grid, the code which loads and presets the posts uses [fromPost] for further posts loading.
  /// The boorus which do not support geting posts down a certain post number should keep a page number internally,
  /// and return it in [currentPage].
  Future<(List<Post>, int?)> page(
    int p,
    String tags,
    BooruTagging excludedTags, {
    SafeMode? overrideSafeMode,
  });

  /// Get the post's notes.
  /// Usually used for translations.
  Future<Iterable<String>> notes(int postId);

  /// Get posts down a certain post number.
  /// The boorus which do not support geting posts down a certain post number should keep a page number internally,
  /// and use paging to load the posts.
  Future<(List<Post>, int?)> fromPost(
      int postId, String tags, BooruTagging excludedTags,
      {SafeMode? overrideSafeMode});

  /// Tag completition, this shouldn't present more than 10 at a time.
  Future<List<BooruTag>> completeTag(String tag);

  /// Sets the cookies for all the requests done with the [client].
  /// This is useful with Cloudlfare, but currently is usesless.
  // void setCookies(List<Cookie> cookies);

  /// [fromSettings] returns a selected *booru API, consulting the settings.
  /// Some *booru have no way to retreive posts down
  /// of a post number, in this case [page] comes in handy:
  /// that is, it makes refreshes on restore few.
  static BooruAPI fromSettings(Dio client, PageSaver pageSaver) {
    return BooruAPI.fromEnum(
      SettingsService.currentData.selectedBooru,
      client,
      pageSaver,
    );
  }

  static Dio defaultClientForBooru(Booru booru) {
    final jar = UnsaveableCookieJar(CookieJarTab().get(booru));
    final Dio dio = Dio();
    dio.interceptors.add(CookieManager(jar));

    return dio;
  }

  static BooruAPI fromEnum(Booru booru, Dio client, PageSaver pageSaver) {
    return switch (booru) {
      Booru.danbooru => Danbooru(client),
      Booru.gelbooru => Gelbooru(client, pageSaver),
    };
  }

  static int numberOfElementsPerRefresh() {
    final settings = GridSettingsBooru.current();
    if (settings.layoutType == GridLayoutType.list) {
      return 20;
    }

    return 15 * settings.columns.number;
  }
}

class BooruTag {
  const BooruTag(this.tag, this.count);

  final String tag;
  final int count;
}

abstract class PageSaver {
  const PageSaver();

  void save(int page);

  int get current;
}

class EmptyPageSaver implements PageSaver {
  EmptyPageSaver();

  @override
  int current = 0;

  @override
  void save(int page) {
    current = page;
  }
}

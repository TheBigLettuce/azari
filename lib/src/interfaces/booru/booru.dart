// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

/// Enum which holds all the currently supported sites by this app.
/// All of the implementations of [BooruAPI] should be added here.
/// Prefixes, names and urls should be unique.
enum Booru {
  gelbooru(string: "Gelbooru", prefix: "g", url: "gelbooru.com"),
  danbooru(string: "Danbooru", prefix: "d", url: "danbooru.donmai.us");

  const Booru({
    required this.string,
    required this.prefix,
    required this.url,
  });

  /// Name. starting with an uppercase letter.
  final String string;

  /// Prefix ensures that the filenames will be unique.
  /// This is useful in the folders which have images from various sources.
  final String prefix;

  /// Url to the booru. All the requests are made to the booru API use this.
  /// Scheme is always assumed to be https.
  final String url;

  /// Constructs a link to the post to be loaded in the browser, outside the app.
  Uri browserLink(int id) {
    return switch (this) {
      Booru.gelbooru => Uri.https(url, "/index.php", {
          "page": "post",
          "s": "view",
          "id": id.toString(),
        }),
      Booru.danbooru => Uri.https(url, "/posts/$id"),
    };
  }

  Uri browserLinkSearch(String tags) {
    return switch (this) {
      Booru.gelbooru => Uri.https(url, "/index.php", {
          "page": "post",
          "s": "list",
          "tags": tags,
        }),
      Booru.danbooru => Uri.https(url, "/posts?tags=$tags"),
    };
  }

  static Booru? fromPrefix(String prefix) {
    for (final b in Booru.values) {
      if (b.prefix == prefix) {
        return b;
      }
    }

    return null;
  }
}

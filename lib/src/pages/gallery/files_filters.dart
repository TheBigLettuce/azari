// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:flutter/material.dart";

/// Data for the [FilteringMode.same].
class SameFilterAccumulator {
  SameFilterAccumulator.empty()
      : data = {},
        skipped = 0;

  final Map<int, Map<int, File>> data;
  int skipped;
}

(Iterable<File>, dynamic) tag(
  Iterable<File> cells,
  String searchText,
) {
  if (searchText.isEmpty) {
    return (cells, null);
  }

  return (
    cells.where(
      (element) {
        for (final tag in searchText.split(" ")) {
          if (!element.tags.containsKey(tag)) {
            return false;
          }
        }

        return true;
      },
    ),
    null
  );
}

(Iterable<File>, dynamic) tagReversed(
  Iterable<File> cells,
  String searchText,
) {
  return (
    cells.where(
      (element) {
        for (final tag in searchText.split(" ")) {
          if (element.tags.containsKey(tag)) {
            return false;
          }
        }

        return true;
      },
    ),
    null
  );
}

(Iterable<File>, dynamic) favorite(
  Iterable<File> cells,
  FavoritePostSourceService favoritePosts,
  String searchText,
) {
  return (
    cells.where(
      (element) {
        final isFavorite =
            favoritePosts.cache.isFavorite(element.res!.$1, element.res!.$2);

        if (searchText.isNotEmpty) {
          return element.res != null &&
              isFavorite &&
              element.tags.containsKey(searchText);
        }

        return element.res != null && isFavorite;
      },
    ),
    null
  );
}

(Iterable<File>, dynamic) untagged(
  Iterable<File> cells,
) {
  return (
    cells.where(
      (element) => element.tags.isEmpty,
    ),
    null
  );
}

(Iterable<File>, dynamic) video(
  Iterable<File> cells,
) {
  return (cells.where((element) => element.isVideo), null);
}

(Iterable<File>, dynamic) gif(
  Iterable<File> cells,
) {
  return (cells.where((element) => element.isGif), null);
}

(Iterable<File>, dynamic) duplicate(
  Iterable<File> cells,
) {
  return (cells.where((element) => element.isDuplicate), null);
}

(Iterable<File>, dynamic) original(
  Iterable<File> cells,
) {
  return (
    cells.where(
      (element) => element.tags.containsKey("original"),
    ),
    null
  );
}

Iterable<(File f, int? h)> _getDifferenceHash(
  Iterable<File> cells,
  ThumbnailService thumbnailService,
) sync* {
  for (final cell in cells) {
    yield (cell, thumbnailService.get(cell.id)?.differenceHash);
  }
}

(Iterable<File>, dynamic) same(
  Iterable<File> cells,
  dynamic data, {
  required bool end,
  required VoidCallback onSkipped,
  required ResourceSource<int, File> source,
  required ThumbnailService thumbnailService,
}) {
  final accu =
      (data as SameFilterAccumulator?) ?? SameFilterAccumulator.empty();

  for (final (cell, hash) in _getDifferenceHash(cells, thumbnailService)) {
    if (hash == null) {
      accu.skipped++;
      continue;
    } else if (hash == 0) {
      continue;
    }

    final prev = accu.data[hash] ?? {};

    accu.data[hash] = {...prev, cell.id: cell};
  }

  if (end) {
    if (accu.skipped != 0) {
      onSkipped();
    }

    return (
      () sync* {
        for (final i in accu.data.values) {
          if (i.length > 1) {
            for (final v in i.values) {
              yield v;
            }
          }
        }
      }(),
      accu
    );
  }

  return ([], accu);
}

Future<void> loadNextThumbnails(
  ResourceSource<int, File> source,
  void Function() callback,
  ThumbnailService thumbnailService,
  CachedThumbs cachedThumbs,
) async {
  var offset = 0;
  var count = 0;
  final List<Future<ThumbId>> thumbnails = [];

  for (;;) {
    final elems = source.backingStorage.skip(offset).take(40);
    offset += elems.length;

    if (elems.isEmpty) {
      break;
    }

    for (final file in elems) {
      if (thumbnailService.get(file.id) == null) {
        count++;

        thumbnails.add(cachedThumbs.get(file.id));

        if (thumbnails.length > 8) {
          thumbnailService.addAll(await thumbnails.wait);
          thumbnails.clear();
        }
      }
    }

    if (count >= 80) {
      break;
    }
  }

  if (thumbnails.isNotEmpty) {
    thumbnailService.addAll(await thumbnails.wait);
  }

  callback();
}

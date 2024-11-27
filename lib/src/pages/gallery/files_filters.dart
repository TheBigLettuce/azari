// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/platform/gallery_api.dart";
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
) {
  return (
    cells.where(
      (element) =>
          element.res != null &&
          favoritePosts.contains(element.res!.$1, element.res!.$2),
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
) sync* {
  for (final cell in cells) {
    yield (cell, ThumbnailService.db().get(cell.id)?.differenceHash);
  }
}

(Iterable<File>, dynamic) same(
  BuildContext context,
  Iterable<File> cells,
  dynamic data, {
  required bool end,
  required void Function() performSearch,
  required ResourceSource<int, File> source,
}) {
  final accu =
      (data as SameFilterAccumulator?) ?? SameFilterAccumulator.empty();

  for (final (cell, hash) in _getDifferenceHash(cells)) {
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
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.resultsIncomplete),
            duration: const Duration(seconds: 20),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.loadMoreLabel,
              onPressed: () {
                _loadNextThumbnails(source, () {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.loaded),
                      ),
                    );
                    performSearch();
                  } catch (_) {}
                });
              },
            ),
          ),
        );
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

Future<void> _loadNextThumbnails(
  ResourceSource<int, File> source,
  void Function() callback,
) async {
  final thumbnailService = ThumbnailService.db();

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

        thumbnails.add(GalleryApi().thumbs.get(file.id));

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

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/plugs/gallery.dart";
import "package:azari/src/plugs/gallery_management_api.dart";
import "package:azari/src/plugs/platform_functions.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

/// Data for the [FilteringMode.same].
class SameFilterAccumulator {
  SameFilterAccumulator.empty()
      : data = {},
        skipped = 0;

  final Map<int, Map<int, GalleryFile>> data;
  int skipped;
}

(Iterable<GalleryFile>, dynamic) tag(
  Iterable<GalleryFile> cells,
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

(Iterable<GalleryFile>, dynamic) tagReversed(
  Iterable<GalleryFile> cells,
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

(Iterable<GalleryFile>, dynamic) favorite(
  Iterable<GalleryFile> cells,
  FavoriteFileService favoriteFile,
) {
  return (
    cells.where(
      (element) => favoriteFile.cachedValues.containsKey(element.id),
    ),
    null
  );
}

(Iterable<GalleryFile>, dynamic) untagged(
  Iterable<GalleryFile> cells,
) {
  return (
    cells.where(
      (element) => element.tags.isEmpty,
    ),
    null
  );
}

(Iterable<GalleryFile>, dynamic) video(
  Iterable<GalleryFile> cells,
) {
  return (cells.where((element) => element.isVideo), null);
}

(Iterable<GalleryFile>, dynamic) gif(
  Iterable<GalleryFile> cells,
) {
  return (cells.where((element) => element.isGif), null);
}

(Iterable<GalleryFile>, dynamic) duplicate(
  Iterable<GalleryFile> cells,
) {
  return (cells.where((element) => element.isDuplicate), null);
}

(Iterable<GalleryFile>, dynamic) original(
  Iterable<GalleryFile> cells,
) {
  return (
    cells.where(
      (element) => element.tags.containsKey("original"),
    ),
    null
  );
}

Iterable<(GalleryFile f, int? h)> _getDifferenceHash(
  Iterable<GalleryFile> cells,
) sync* {
  for (final cell in cells) {
    yield (cell, ThumbnailService.db().get(cell.id)?.differenceHash);
  }
}

(Iterable<GalleryFile>, dynamic) same(
  BuildContext context,
  Iterable<GalleryFile> cells,
  dynamic data, {
  required bool end,
  required void Function() performSearch,
  required ResourceSource<int, GalleryFile> source,
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
  ResourceSource<int, GalleryFile> source,
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

        thumbnails.add(GalleryManagementApi.current().thumbs.get(file.id));

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

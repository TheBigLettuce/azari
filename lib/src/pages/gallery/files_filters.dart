// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/platform_functions.dart";

/// Data for the [FilteringMode.same].
class SameFilterAccumulator {
  SameFilterAccumulator.empty()
      : data = {},
        skipped = 0;

  final Map<int, Map<int, GalleryFile>> data;
  int skipped;
}

abstract class FileFilters {
  const FileFilters();

  static (Iterable<GalleryFile>, dynamic) tag(
    Iterable<GalleryFile> cells,
    String searchText,
    PostTags postTags,
  ) {
    if (searchText.isEmpty) {
      return (cells, null);
    }

    return (
      cells.where(
        (element) => postTags.contains(element.name, searchText),
      ),
      null
    );
  }

  static (Iterable<GalleryFile>, dynamic) tagReversed(
    Iterable<GalleryFile> cells,
    String searchText,
    PostTags postTags,
  ) {
    return (
      cells.where(
        (element) => !postTags.contains(element.name, searchText),
      ),
      null
    );
  }

  static (Iterable<GalleryFile>, dynamic) favorite(
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

  static (Iterable<GalleryFile>, dynamic) untagged(
    Iterable<GalleryFile> cells,
    LocalTagsService localTags,
  ) {
    return (
      cells.where(
        (element) => !localTags.cachedValues.containsKey(element.name),
      ),
      null
    );
  }

  static (Iterable<GalleryFile>, dynamic) video(
    Iterable<GalleryFile> cells,
  ) {
    return (cells.where((element) => element.isVideo), null);
  }

  static (Iterable<GalleryFile>, dynamic) gif(
    Iterable<GalleryFile> cells,
  ) {
    return (cells.where((element) => element.isGif), null);
  }

  static (Iterable<GalleryFile>, dynamic) duplicate(
    Iterable<GalleryFile> cells,
  ) {
    return (cells.where((element) => element.isDuplicate), null);
  }

  static (Iterable<GalleryFile>, dynamic) original(
    Iterable<GalleryFile> cells,
    LocalTagsService localTags,
  ) {
    return (
      cells.where(
        (element) =>
            localTags.cachedValues[element.name]?.contains("original") ?? false,
      ),
      null
    );
  }

  static (Iterable<GalleryFile>, dynamic) same(
    BuildContext context,
    Iterable<GalleryFile> cells,
    dynamic data, {
    required bool end,
    required void Function() performSearch,
    required ResourceSource<int, GalleryFile> source,
  }) {
    final accu =
        (data as SameFilterAccumulator?) ?? SameFilterAccumulator.empty();

    Iterable<(GalleryFile f, int? h)> getDifferenceHash(
      Iterable<GalleryFile> cells,
    ) sync* {
      for (final cell in cells) {
        yield (cell, ThumbnailService.db().get(cell.id)?.differenceHash);
      }
    }

    for (final (cell, hash) in getDifferenceHash(cells)) {
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
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
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

  static int hammingDistance(int first, int second) => bitCount(first ^ second);

  // stolen from internet
  static int bitCount(int nn) {
    int n = nn;

    n = n - ((n >> 1) & 0x5555555555555555);
    n = (n & 0x3333333333333333) + ((n >> 2) & 0x3333333333333333);
    n = (n + (n >> 4)) & 0x0f0f0f0f0f0f0f0f;
    n = n + (n >> 8);
    n = n + (n >> 16);
    n = n + (n >> 32);
    return n & 0x7f;
  }
}

Future<void> _loadNextThumbnails(
    ResourceSource<int, GalleryFile> source, void Function() callback) async {
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

        thumbnails.add(GalleryManagementApi.current().getCachedThumb(file.id));

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

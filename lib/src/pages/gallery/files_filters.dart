// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/impl/isar/schemas/gallery/system_gallery_directory_file.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";

/// Data for the [FilteringMode.same].
class SameFilterAccumulator {
  SameFilterAccumulator.empty()
      : data = {},
        skipped = 0;

  final Map<int, Set<int>> data;
  int skipped;
}

abstract class FileFilters {
  const FileFilters();

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) tag(
    Iterable<SystemGalleryDirectoryFile> cells,
    String searchText,
  ) {
    if (searchText.isEmpty) {
      return (cells, null);
    }

    return (
      cells.where(
        (element) => PostTags.g.containsTagMultiple(element.name, searchText),
      ),
      null
    );
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) tagReversed(
    Iterable<SystemGalleryDirectoryFile> cells,
    String searchText,
  ) {
    if (searchText.isEmpty) {
      return (cells, null);
    }

    return (
      cells.where(
        (element) => !PostTags.g.containsTagMultiple(element.name, searchText),
      ),
      null
    );
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) favorite(
    Iterable<SystemGalleryDirectoryFile> cells,
  ) {
    return (cells.where((element) => element.isFavorite), null);
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) untagged(
    Iterable<SystemGalleryDirectoryFile> cells,
  ) {
    return (
      cells.where((element) => PostTags.g.getTagsPost(element.name).isEmpty),
      null
    );
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) video(
    Iterable<SystemGalleryDirectoryFile> cells,
  ) {
    return (cells.where((element) => element.isVideo), null);
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) gif(
    Iterable<SystemGalleryDirectoryFile> cells,
  ) {
    return (cells.where((element) => element.isGif), null);
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) duplicate(
    Iterable<SystemGalleryDirectoryFile> cells,
  ) {
    return (cells.where((element) => element.isDuplicate), null);
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) original(
    Iterable<SystemGalleryDirectoryFile> cells,
  ) {
    return (
      cells
          .where((element) => PostTags.g.containsTag(element.name, "original")),
      null
    );
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) same(
    BuildContext context,
    Iterable<SystemGalleryDirectoryFile> cells,
    dynamic data,
    GalleryFilesExtra extra, {
    required bool end,
    required SystemGalleryDirectoryFile Function(int i) getCell,
    required void Function() performSearch,
  }) {
    final accu =
        (data as SameFilterAccumulator?) ?? SameFilterAccumulator.empty();

    Iterable<(int isarId, int? h)> getDifferenceHash(
      Iterable<SystemGalleryDirectoryFile> cells,
    ) sync* {
      for (final cell in cells) {
        yield (cell.isarId!, cell.getThumbnail(cell.id)?.differenceHash);
      }
    }

    for (final (isarId, hash) in getDifferenceHash(cells)) {
      if (hash == null) {
        accu.skipped++;
        continue;
      } else if (hash == 0) {
        continue;
      }

      final prev = accu.data[hash] ?? {};

      accu.data[hash] = {...prev, isarId};
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
                extra.loadNextThumbnails(() {
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
              for (final v in i) {
                final file = getCell(v);
                file.isarId = null;
                yield file;
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

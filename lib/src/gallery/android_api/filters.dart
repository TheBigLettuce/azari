// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/search_filter_grid.dart';

import '../../booru/tags/tags.dart';
import '../../schemas/android_gallery_directory_file.dart';
import 'android_api_directories.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Data for the [FilteringMode.same].
class SameFilterAccumulator {
  final Map<int, Set<int>> data;
  int skipped;

  SameFilterAccumulator.empty()
      : data = {},
        skipped = 0;
}

class Filters {
  static (Iterable<SystemGalleryDirectoryFile>, dynamic) tag(
      Iterable<SystemGalleryDirectoryFile> cells, String searchText) {
    if (searchText.isEmpty) {
      return (cells, null);
    }

    return (
      cells.where((element) =>
          PostTags().containsTagMultiple(element.name, searchText)),
      null
    );
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) tagReversed(
      Iterable<SystemGalleryDirectoryFile> cells, String searchText) {
    if (searchText.isEmpty) {
      return (cells, null);
    }

    return (
      cells.where((element) =>
          !PostTags().containsTagMultiple(element.name, searchText)),
      null
    );
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) favorite(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (cells.where((element) => element.isFavorite()), null);
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) untagged(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (
      cells.where((element) => PostTags().getTagsPost(element.name).isEmpty),
      null
    );
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) video(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (cells.where((element) => element.isVideo), null);
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) gif(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (cells.where((element) => element.isGif), null);
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) duplicate(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (cells.where((element) => element.isDuplicate()), null);
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) original(
      Iterable<SystemGalleryDirectoryFile> cells) {
    return (
      cells
          .where((element) => PostTags().containsTag(element.name, "original")),
      null
    );
  }

  static (Iterable<SystemGalleryDirectoryFile>, dynamic) same(
      BuildContext context,
      Iterable<SystemGalleryDirectoryFile> cells,
      SameFilterAccumulator? accu,
      AndroidGalleryFilesExtra extra,
      {required bool end,
      required bool expensiveHash,
      required SystemGalleryDirectoryFile Function(int i) getCell,
      required void Function() performSearch}) {
    accu ??= SameFilterAccumulator.empty();

    for (final (isarId, hash)
        in extra.getDifferenceHash(cells, expensiveHash)) {
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
      Iterable<SystemGalleryDirectoryFile> ret;

      if (expensiveHash) {
        final Set<int> distanceSet = {};

        accu.data.removeWhere((key, value) {
          if (value.length > 1) {
            for (final e in value) {
              distanceSet.add(e);
            }
            return true;
          }
          return false;
        });

        for (final first in accu.data.keys) {
          for (final second in accu.data.keys) {
            if (first == second) {
              continue;
            }

            final distance = hammingDistance(first, second);
            if (distance < 2) {
              for (final e in accu.data[first]!) {
                distanceSet.add(e);
              }

              for (final e in accu.data[second]!) {
                distanceSet.add(e);
              }
            }
          }
        }

        ret = () sync* {
          for (final i in distanceSet) {
            var file = getCell(i);
            file.isarId = null;
            yield file;
          }
        }();
      } else {
        ret = () sync* {
          for (final i in accu!.data.values) {
            if (i.length > 1) {
              for (final v in i) {
                var file = getCell(v);
                file.isarId = null;
                yield file;
              }
            }
          }
        }();
      }

      if (accu.skipped != 0) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.resultsIncomplete),
          duration: const Duration(seconds: 20),
          action: SnackBarAction(
              label: AppLocalizations.of(context)!.loadMoreLabel,
              onPressed: () {
                extra.loadNextThumbnails(() {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        duration: 4.seconds,
                        content: Text(AppLocalizations.of(context)!.loaded)));
                    performSearch();
                  } catch (_) {}
                }, expensiveHash);
              }),
        ));
      }

      return (ret, accu);
    }

    return ([], accu);
  }

  static int hammingDistance(int first, int second) => bitCount(first ^ second);

  // stolen from internet
  static int bitCount(int n) {
    n = n - ((n >> 1) & 0x5555555555555555);
    n = (n & 0x3333333333333333) + ((n >> 2) & 0x3333333333333333);
    n = (n + (n >> 4)) & 0x0f0f0f0f0f0f0f0f;
    n = n + (n >> 8);
    n = n + (n >> 16);
    n = n + (n >> 32);
    return n & 0x7f;
  }
}

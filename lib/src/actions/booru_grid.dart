// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../booru/downloader/downloader.dart';
import '../booru/interface.dart';
import '../booru/tags/tags.dart';
import '../db/isar.dart';
import '../schemas/download_file.dart';
import '../schemas/local_tag_dictionary.dart';
import '../schemas/post.dart';
import '../schemas/settings.dart';
import '../schemas/tags.dart';
import '../widgets/grid/callback_grid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BooruGridActions {
  static GridBottomSheetAction<T> download<T extends PostBase>(
      BuildContext context, BooruAPI api) {
    final downloader = Downloader();

    return GridBottomSheetAction(Icons.download, (selected) {
      for (final element in selected) {
        PostTags().addTagsPost(element.filename(), element.tags, true);
        downloader
            .add(File.d(element.fileUrl, api.booru.url, element.filename()));
      }
    },
        true,
        GridBottomSheetActionExplanation(
          label: AppLocalizations.of(context)!.downloadActionLabel,
          body: AppLocalizations.of(context)!.downloadActionBody,
        ));
  }

  static GridBottomSheetAction<T> favorites<T extends PostBase>(T? p) {
    final isFavorite = p != null && Settings.isFavorite(p.fileUrl);
    return GridBottomSheetAction(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        (selected) {
      Settings.addRemoveFavorites(selected);
      settingsIsar().writeTxnSync(
        () {
          for (final post in selected) {
            settingsIsar().localTagDictionarys.putAllSync(post.tags
                .map((e) => LocalTagDictionary(
                    HtmlUnescape().convert(e),
                    (settingsIsar()
                                .localTagDictionarys
                                .getSync(fastHash(e))
                                ?.frequency ??
                            0) +
                        1))
                .toList());
          }
        },
      );
    },
        true,
        const GridBottomSheetActionExplanation(
          label: "Favorite", // TODO: change
          body: "Add selected posts to the favorites.", // TODO: change
        ),
        color: isFavorite ? Colors.red.shade900 : null);
  }
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../../../net/downloader.dart';
import '../../../interfaces/booru.dart';
import '../../../db/post_tags.dart';
import '../../../db/initalize_db.dart';
import '../../../db/schemas/download_file.dart';
import '../../../db/schemas/local_tag_dictionary.dart';
import '../../../db/schemas/post.dart';
import '../../../db/schemas/settings.dart';
import '../../../db/schemas/tags.dart';
import '../callback_grid.dart';

class BooruGridActions {
  static GridAction<T> download<T extends PostBase>(
      BuildContext context, BooruAPI api) {
    return GridAction(
      Icons.download,
      (selected) {
        final settings = Settings.fromDb();

        PostTags.g.addTagsPostAll(selected.map((e) => (e.filename(), e.tags)));
        Downloader.g.addAll(
            selected.map((e) => DownloadFile.d(
                url: e.fileUrl,
                site: api.booru.url,
                name: e.filename(),
                thumbUrl: e.previewUrl)),
            settings);
      },
      true,
    );
  }

  static GridAction<T> favorites<T extends PostBase>(BuildContext context, T? p,
      {bool showDeleteSnackbar = false}) {
    final isFavorite = p != null && Settings.isFavorite(p.fileUrl);
    return GridAction(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        (selected) {
      Settings.addRemoveFavorites(context, selected, showDeleteSnackbar);
      Dbs.g.main.writeTxnSync(
        () {
          for (final post in selected) {
            Dbs.g.main.localTagDictionarys.putAllSync(post.tags
                .map((e) => LocalTagDictionary(
                    HtmlUnescape().convert(e),
                    (Dbs.g.main.localTagDictionarys
                                .getSync(fastHash(e))
                                ?.frequency ??
                            0) +
                        1))
                .toList());
          }
        },
      );
    }, true,
        color: isFavorite ? Colors.red.shade900 : null,
        animate: p != null,
        play: !isFavorite);
  }
}

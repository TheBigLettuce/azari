// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/db/schemas/downloader/download_file.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/db/schemas/tags/local_tag_dictionary.dart';
import 'package:gallery/src/db/tags/post_tags.dart';

import '../../../net/downloader.dart';
import '../metadata/grid_action.dart';

class BooruGridActions {
  static GridAction<T> download<T extends PostBase>(BuildContext context) {
    return GridAction(
      Icons.download,
      (selected) {
        final settings = Settings.fromDb();

        PostTags.g.addTagsPostAll(selected.map((e) => (e.filename(), e.tags)));
        Downloader.g.addAll(
            selected.map((e) => DownloadFile.d(
                url: e.fileUrl,
                site: settings.selectedBooru.url,
                name: e.filename(),
                thumbUrl: e.previewUrl)),
            settings);
      },
      true,
    );
  }

  static GridAction<T> favorites<T extends PostBase>(BuildContext context) {
    return GridAction(
        Icons.favorite_border_rounded,
        (selected) {
          Settings.addRemoveFavorites(context, selected, true);
          for (final post in selected) {
            LocalTagDictionary.addAll(post.tags);
          }
        },
        true,
        testSingle: (cell) {
          final isFavorite = Settings.isFavorite(cell.fileUrl);

          return GridActionExtra(
            overrideIcon: isFavorite ? Icons.favorite_rounded : null,
            color: isFavorite ? Colors.red.shade900 : null,
            animate: true,
            play: !isFavorite,
          );
        });
  }
}

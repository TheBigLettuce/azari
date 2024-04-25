// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/schemas/booru/post.dart";
import "package:gallery/src/db/schemas/downloader/download_file.dart";
import "package:gallery/src/db/schemas/settings/hidden_booru_post.dart";
import "package:gallery/src/db/schemas/settings/settings.dart";
import "package:gallery/src/db/schemas/tags/local_tag_dictionary.dart";
import "package:gallery/src/db/services/settings.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/net/downloader.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

class BooruGridActions {
  const BooruGridActions();

  static GridAction<Post> hide(BuildContext context) {
    return GridAction(
      Icons.hide_image_rounded,
      (selected) {
        if (selected.isEmpty) {
          return;
        }

        final toDelete = <(int, Booru)>[];
        final toAdd = <HiddenBooruPost>[];

        final booru = selected.first.booru;

        for (final cell in selected) {
          if (HiddenBooruPost.isHidden(cell.id, booru)) {
            toDelete.add((cell.id, booru));
          } else {
            toAdd.add(HiddenBooruPost(booru, cell.id, cell.previewUrl));
          }
        }

        HiddenBooruPost.addAll(toAdd);
        HiddenBooruPost.removeAll(toDelete);
      },
      true,
    );
  }

  static GridAction<T> download<T extends PostBase>(
    BuildContext context,
    Booru booru,
  ) {
    return GridAction(
      Icons.download,
      (selected) {
        final settings = SettingsService.currentData;

        PostTags.g.addTagsPostAll(
          selected.map((e) => (e.filename(), e.tags)),
        );
        Downloader.g.addAll(
          selected.map(
            (e) => DownloadFile.d(
              url: e.fileUrl,
              site: booru.url,
              name: e.filename(),
              thumbUrl: e.previewUrl,
            ),
          ),
          settings,
        );
      },
      true,
      animate: true,
    );
  }

  static GridAction<T> favorites<T extends PostBase>(
    BuildContext context, {
    bool showDeleteSnackbar = false,
  }) {
    return GridAction(
      Icons.favorite_border_rounded,
      (selected) {
        IsarSettings.addRemoveFavorites(context, selected, showDeleteSnackbar);
        for (final post in selected) {
          LocalTagDictionary.addAll(post.tags);
        }
      },
      true,
    );
  }
}

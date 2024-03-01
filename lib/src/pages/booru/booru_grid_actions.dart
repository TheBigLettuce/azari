// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/db/schemas/settings/hidden_booru_post.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';

import '../../net/downloader.dart';
import '../../db/tags/post_tags.dart';
import '../../db/schemas/downloader/download_file.dart';
import '../../db/schemas/tags/local_tag_dictionary.dart';
import '../../db/schemas/settings/settings.dart';
import '../../widgets/grid_frame/grid_frame.dart';

class BooruGridActions {
  static GridAction<T> hide<T extends PostBase>(
      BuildContext context, void Function() setState,
      {PostBase? post}) {
    return GridAction(Icons.hide_image_rounded, (selected) {
      if (selected.isEmpty) {
        return;
      }

      final toDelete = <(int, Booru)>[];
      final toAdd = <HiddenBooruPost>[];

      final booru = Booru.fromPrefix(selected.first.prefix)!;

      for (final cell in selected) {
        if (HiddenBooruPost.isHidden(cell.id, booru)) {
          toDelete.add((cell.id, booru));
        } else {
          toAdd.add(HiddenBooruPost(booru, cell.id, cell.previewUrl));
        }
      }

      HiddenBooruPost.addAll(toAdd);
      HiddenBooruPost.removeAll(toDelete);

      setState();
    }, true,
        color: post != null &&
                HiddenBooruPost.isHidden(
                    post.id, Booru.fromPrefix(post.prefix)!)
            ? Theme.of(context).colorScheme.primary
            : null);
  }

  static GridAction<T> download<T extends PostBase>(
      BuildContext context, Booru booru) {
    return GridAction(Icons.download, (selected) {
      final settings = Settings.fromDb();

      PostTags.g.addTagsPostAll(selected.map((e) => (e.filename(), e.tags)));
      Downloader.g.addAll(
          selected.map((e) => DownloadFile.d(
              url: e.fileUrl,
              site: booru.url,
              name: e.filename(),
              thumbUrl: e.previewUrl)),
          settings);
    }, true, animate: true);
  }

  static GridAction<T> favorites<T extends PostBase>(BuildContext context, T? p,
      {bool showDeleteSnackbar = false}) {
    final isFavorite = p != null && Settings.isFavorite(p.fileUrl);
    return GridAction(
      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      (selected) {
        Settings.addRemoveFavorites(context, selected, showDeleteSnackbar);
        for (final post in selected) {
          LocalTagDictionary.addAll(post.tags);
        }
      },
      true,
      color: isFavorite ? Colors.red.shade900 : null,
      animate: p != null,
      play: !isFavorite,
    );
  }
}

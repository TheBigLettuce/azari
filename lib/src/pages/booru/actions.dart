// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

GridAction<Post> hide(
  BuildContext context,
  HiddenBooruPostService hiddenPost,
) {
  return GridAction(
    Icons.hide_image_rounded,
    (selected) {
      if (selected.isEmpty) {
        return;
      }

      final toDelete = <(int, Booru)>[];
      final toAdd = <HiddenBooruPostData>[];

      final booru = selected.first.booru;

      for (final cell in selected) {
        if (hiddenPost.isHidden(cell.id, booru)) {
          toDelete.add((cell.id, booru));
        } else {
          toAdd.add(
            HiddenBooruPostData(
              thumbUrl: cell.previewUrl,
              postId: cell.id,
              booru: booru,
            ),
          );
        }
      }

      hiddenPost.addAll(toAdd);
      hiddenPost.removeAll(toDelete);
    },
    true,
  );
}

GridAction<T> download<T extends Post>(
  BuildContext context,
  Booru booru,
  PathVolume? thenMoveTo,
) {
  return GridAction(
    Icons.download,
    (selected) => selected.downloadAll(
      DownloadManager.of(context),
      PostTags.fromContext(context),
      thenMoveTo,
    ),
    true,
    animate: true,
  );
}

GridAction<T> favorites<T extends PostImpl>(
  BuildContext context,
  FavoritePostSourceService favoritePost, {
  bool showDeleteSnackbar = false,
}) {
  return GridAction<T>(
    Icons.favorite_border_rounded,
    (selected) {
      final ret = favoritePost.addRemove(selected);

      if (ret.isNotEmpty && showDeleteSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 20),
            behavior: SnackBarBehavior.floating,
            content: Text(AppLocalizations.of(context)!.deletedFromFavorites),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.undoLabel,
              onPressed: () {
                favoritePost.addRemove(ret);
              },
            ),
          ),
        );
      }
    },
    true,
  );
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/obj_impls/post_impl.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/widgets/selection_bar.dart";
import "package:flutter/material.dart";

SelectionBarAction hide(
  BuildContext context,
  HiddenBooruPostsService hiddenPost,
) {
  return SelectionBarAction(
    Icons.hide_image_rounded,
    (selected) {
      if (selected.isEmpty) {
        return;
      }

      final toDelete = <(int, Booru)>[];
      final toAdd = <HiddenBooruPostData>[];

      final booru = (selected.first as PostImpl).booru;

      for (final (cell as PostImpl) in selected) {
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

SelectionBarAction downloadPost(
  BuildContext context,
  Booru booru,
  PathVolume? thenMoveTo, {
  required DownloadManager downloadManager,
  required LocalTagsService localTags,
  required SettingsService settingsService,
}) {
  return SelectionBarAction(
    Icons.download,
    (selected) => selected.cast<PostImpl>().downloadAll(
          downloadManager: downloadManager,
          localTags: localTags,
          settingsService: settingsService,
          thenMoveTo: thenMoveTo,
        ),
    true,
    animate: true,
  );
}

// GridAction downloadFavoritePost(
//   BuildContext context,
//   Booru booru,
//   PathVolume? thenMoveTo, {
//   required DownloadManager downloadManager,
//   required LocalTagsService localTags,
//   required SettingsService settingsService,
// }) {
//   return GridAction(
//     Icons.download,
//     (selected) => selected.cast<PostImpl>().downloadAll(
//           downloadManager: downloadManager,
//           localTags: localTags,
//           settingsService: settingsService,
//           thenMoveTo: thenMoveTo,
//         ),
//     true,
//     animate: true,
//   );
// }

SelectionBarAction favorites(
  BuildContext context,
  FavoritePostSourceService favoritePost, {
  bool showDeleteSnackbar = false,
}) {
  return SelectionBarAction(
    Icons.favorite_border_rounded,
    (selected) => favoritePost.addRemove(selected.cast()),
    true,
  );
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:flutter/material.dart";

SelectionBarAction hide(
  BuildContext context,
) {
  return SelectionBarAction(
    Icons.hide_image_rounded,
    (selected) {
      if (selected.isEmpty || HiddenBooruPostsService.available) {
        return;
      }

      final toDelete = <(int, Booru)>[];
      final toAdd = <HiddenBooruPostData>[];

      final booru = (selected.first as PostImpl).booru;

      for (final (cell as PostImpl) in selected) {
        if (const HiddenBooruPostsService().isHidden(cell.id, booru)) {
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

      const HiddenBooruPostsService()
        ..addAll(toAdd)
        ..removeAll(toDelete);
    },
    true,
  );
}

SelectionBarAction downloadPost(
  BuildContext context,
  Booru booru,
  PathVolume? thenMoveTo,
) {
  return SelectionBarAction(
    Icons.download,
    (selected) => selected.cast<PostImpl>().downloadAll(thenMoveTo: thenMoveTo),
    true,
    animate: true,
  );
}

SelectionBarAction favorites(
  BuildContext context, {
  bool showDeleteSnackbar = false,
}) {
  return SelectionBarAction(
    Icons.favorite_border_rounded,
    (selected) => FavoritePostSourceService.safe()?.addRemove(selected.cast()),
    true,
  );
}

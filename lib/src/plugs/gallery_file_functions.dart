// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/post_tags.dart";
import "package:gallery/src/db/services/resource_source/filtering_mode.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru_api.dart";
import "package:gallery/src/pages/more/settings/global_progress.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/notifications.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:logging/logging.dart";

List<Sticker> defaultStickersFile(
  BuildContext? context,
  GalleryFile file,
  LocalTagsService localTags,
) {
  return [
    if (file.isVideo) Sticker(FilteringMode.video.icon),
    if (file.isGif) Sticker(FilteringMode.gif.icon),
    if (file.tagsFlat.contains("original"))
      Sticker(FilteringMode.original.icon),
    if (file.isDuplicate) Sticker(FilteringMode.duplicate.icon),
    if (file.tagsFlat.contains("translated"))
      const Sticker(Icons.translate_outlined),
  ];
}

Sticker sizeSticker(int size) {
  if (size == 0) {
    return const Sticker(IconData(0x4B));
  }

  final kb = size / 1000;
  if (kb < 1000) {
    if (kb > 500) {
      return const Sticker(IconData(0x4B));
    } else {
      return const Sticker(IconData(0x6B));
    }
  } else {
    final mb = kb / 1000;
    if (mb > 2) {
      return const Sticker(IconData(0x4D));
    } else {
      return const Sticker(IconData(0x6D));
    }
  }
}

String kbMbSize(BuildContext context, int bytes) {
  if (bytes == 0) {
    return "0";
  }
  final res = bytes / 1000;
  if (res > 1000) {
    return AppLocalizations.of(context)!.megabytes(res / 1000);
  }

  return AppLocalizations.of(context)!.kilobytes(res);
}

Future<void> loadNetworkThumb(
  String filename,
  int id,
  String groupNotifString,
  String notifChannelName,
  ThumbnailService thumbnails,
  PinnedThumbnailService pinnedThumbnails, [
  bool addToPinned = true,
]) async {
  if (GlobalProgress.isThumbLoadingLocked()) {
    return;
  }

  GlobalProgress.lockThumbLoading();

  if (pinnedThumbnails.get(id) != null) {
    GlobalProgress.unlockThumbLoading();
    return;
  }
  final plug = chooseNotificationPlug();

  final notif = await plug.newProgress(
    "",
    savingThumbNotifId,
    groupNotifString,
    notifChannelName,
  );

  notif.update(0, filename);

  final res = DisassembleResult.fromFilename(filename).maybeValue();
  if (res != null) {
    final client = BooruAPI.defaultClientForBooru(res.booru);
    final api = BooruAPI.fromEnum(res.booru, client, PageSaver.noPersist());

    try {
      final post = await api.singlePost(res.id);

      final t = await GalleryManagementApi.current()
          .thumbs
          .saveFromNetwork(post.previewUrl, id);

      thumbnails.delete(id);
      pinnedThumbnails.add(id, t.path, t.differenceHash);
    } catch (e, trace) {
      Logger.root.warning("loadNetworkThumb", e, trace);
    }

    client.close(force: true);
  }

  notif.done();

  GlobalProgress.unlockThumbLoading();
}

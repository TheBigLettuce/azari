// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:logging/logging.dart";

List<Sticker> defaultStickersFile(
  BuildContext? context,
  File file,
  LocalTagsService localTags,
) {
  return [
    if (file.isVideo) Sticker(FilteringMode.video.icon),
    if (file.isGif) Sticker(FilteringMode.gif.icon),
    if (file.tags.containsKey("original")) Sticker(FilteringMode.original.icon),
    if (file.isDuplicate) Sticker(FilteringMode.duplicate.icon),
    if (file.tags.containsKey("translated"))
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
  BuildContext context,
  String filename,
  int id,
  ThumbnailService thumbnails,
  PinnedThumbnailService pinnedThumbnails, [
  bool addToPinned = true,
]) {
  final notifier = GlobalProgressTab.maybeOf(context)
      ?.get("loadNetworkThumb", () => ValueNotifier<Future<void>?>(null));
  if (notifier == null ||
      notifier.value != null ||
      pinnedThumbnails.get(id) != null) {
    return Future.value();
  }

  return notifier.value = Future(() async {
    final notif = await NotificationApi().show(
      id: NotificationApi.savingThumbId,
      title: "",
      channel: NotificationChannel.misc,
      group: NotificationGroup.misc,
    );

    notif.update(0, filename);

    final res = ParsedFilenameResult.fromFilename(filename).maybeValue();
    if (res != null) {
      final client = BooruAPI.defaultClientForBooru(res.booru);
      final api = BooruAPI.fromEnum(res.booru, client, PageSaver.noPersist());

      try {
        final post = await api.singlePost(res.id);

        final t =
            await GalleryApi().thumbs.saveFromNetwork(post.previewUrl, id);

        thumbnails.delete(id);
        pinnedThumbnails.add(id, t.path, t.differenceHash);
      } catch (e, trace) {
        Logger.root.warning("loadNetworkThumb", e, trace);
      }

      client.close(force: true);
    }

    notif.done();
  }).whenComplete(() => notifier.value = null);
}

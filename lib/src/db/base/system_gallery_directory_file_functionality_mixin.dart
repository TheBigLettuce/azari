// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/gallery/favorite_booru_post.dart';
import 'package:gallery/src/db/schemas/gallery/note_gallery.dart';
import 'package:gallery/src/db/schemas/gallery/pinned_thumbnail.dart';
import 'package:gallery/src/db/schemas/gallery/system_gallery_directory_file.dart';
import 'package:gallery/src/db/schemas/gallery/thumbnail.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/interfaces/booru/booru_api.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'package:gallery/src/pages/more/settings/global_progress.dart';
import 'package:gallery/src/plugs/notifications.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';

mixin SystemGalleryDirectoryFileFunctionalityMixin {
  Thumbnail? getThumbnail(int id) {
    return Dbs.g.thumbnail!.thumbnails.getSync(id);
  }

  SystemGalleryDirectoryFile decode(Object result) {
    result as List<Object?>;

    final id = result[0]! as int;
    final name = result[2]! as String;

    return SystemGalleryDirectoryFile(
      isOriginal: PostTags.g.isOriginal(name),
      isDuplicate: RegExp(r'[(][0-9].*[)][.][a-zA-Z0-9].*').hasMatch(name),
      isFavorite: Dbs.g.blacklisted.favoriteBooruPosts.getSync(id) != null,
      tagsFlat: PostTags.g.getTagsPost(name).join(" "),
      notesFlat:
          Dbs.g.main.noteGallerys.getSync(id)?.text.join().toLowerCase() ?? "",
      id: id,
      bucketId: result[1]! as String,
      name: name,
      originalUri: result[3]! as String,
      lastModified: result[4]! as int,
      height: result[5]! as int,
      width: result[6]! as int,
      size: result[7]! as int,
      isVideo: result[8]! as bool,
      isGif: result[9]! as bool,
    );
  }

  List<Sticker> defaultStickers(
      BuildContext? context, SystemGalleryDirectoryFile file) {
    return [
      if (file.isVideo) Sticker(FilteringMode.video.icon),
      if (file.isGif) Sticker(FilteringMode.gif.icon),
      if (file.isOriginal) Sticker(FilteringMode.original.icon),
      if (file.isDuplicate) Sticker(FilteringMode.duplicate.icon),
      if (file.tagsFlat.contains("translated"))
        const Sticker(Icons.translate_outlined)
    ];
  }

  Sticker sizeSticker(int size) {
    if (size == 0) {
      return const Sticker(IconData(0x4B));
    }

    final kb = (size / 1000);
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
}

Future<void> loadNetworkThumb(
    String filename, int id, String groupNotifString, String notifChannelName,
    [bool addToPinned = true]) async {
  if (GlobalProgress.isThumbLoadingLocked()) {
    return;
  }

  GlobalProgress.lockThumbLoading();

  if (Dbs.g.thumbnail!.pinnedThumbnails.getSync(id) != null) {
    GlobalProgress.unlockThumbLoading();
    return;
  }
  final plug = chooseNotificationPlug();

  final notif = await plug.newProgress(
      "", savingThumbNotifId, groupNotifString, notifChannelName);
  notif.update(0, filename);

  try {
    final res = PostTags.g.dissassembleFilename(filename);
    final client = BooruAPI.defaultClientForBooru(res.booru);
    final api = BooruAPI.fromEnum(res.booru, client, EmptyPageSaver());

    try {
      final post = await api.singlePost(res.id);

      final t = await PlatformFunctions.saveThumbNetwork(post.previewUrl, id);

      Dbs.g.thumbnail!
          .writeTxnSync(() => Dbs.g.thumbnail!.thumbnails.deleteSync(id));

      Dbs.g.thumbnail!.writeTxnSync(() => Dbs.g.thumbnail!.pinnedThumbnails
          .putSync(PinnedThumbnail(id, t.differenceHash, t.path)));
    } catch (e) {
      log("video thumb 2", level: Level.WARNING.value, error: e);
    }

    client.close(force: true);
  } catch (_) {}

  notif.done();

  GlobalProgress.unlockThumbLoading();
}

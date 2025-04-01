// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/translation_notes.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";

class FileActionChips extends StatelessWidget {
  const FileActionChips({
    super.key,
    required this.file,
    required this.tags,
    required this.hasTranslation,
  });

  final bool hasTranslation;

  final File file;
  final ImageViewTags tags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (tags.res != null)
            RedownloadChip(
              key: file.uniqueKey(),
              file: file,
              res: tags.res,
            ),
          if (!file.isVideo && !file.isGif) SetWallpaperChip(id: file.id),
          if (tags.res != null && hasTranslation)
            TranslationNotesChip(
              postId: tags.res!.id,
              booru: tags.res!.booru,
            ),
        ],
      ),
    );
  }
}

class RedownloadChip extends StatelessWidget {
  const RedownloadChip({
    super.key,
    required this.file,
    required this.res,
  });

  final File file;
  final ParsedFilenameResult? res;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    final task = const TasksService().status<RedownloadChip>(context);

    return ActionChip(
      onPressed: task.isWaiting
          ? null
          : () => const TasksService().add<RedownloadChip>(
                () => redownloadFiles(l10n, [file]),
              ),
      label: Text(l10n.redownloadLabel),
      avatar: const Icon(
        Icons.download_outlined,
        size: 18,
      ),
    );
  }
}

Future<void> redownloadFiles(AppLocalizations l10n, List<File> files) async {
  if (!DownloadManager.available || !FilesApi.available) {
    return Future.value();
  }

  final clients = <Booru, Dio>{};
  final apis = <Booru, BooruAPI>{};

  final progress = await const NotificationApi().show(
    id: const NotificationChannels().redownloadFiles,
    title: l10n.redownloadFetchingUrls,
    group: NotificationGroup.misc,
    channel: NotificationChannel.misc,
    body: l10n.redownloadRedowloadingFiles(files.length),
  );

  try {
    progress?.setTotal(files.length);

    final posts = <Post>[];
    final actualFiles = <File>[];

    for (final (index, file) in files.indexed) {
      progress?.update(index, "$index / ${files.length}");

      final res = ParsedFilenameResult.fromFilename(file.name).maybeValue();
      if (res == null) {
        continue;
      }

      final dio = clients.putIfAbsent(
        res.booru,
        () => BooruAPI.defaultClientForBooru(res.booru),
      );
      final api = apis.putIfAbsent(
        res.booru,
        () => BooruAPI.fromEnum(res.booru, dio),
      );

      try {
        posts.add(await api.singlePost(res.id));
        actualFiles.add(file);
      } catch (e, trace) {
        Logger.root.warning("RedownloadTile", e, trace);
      }
    }

    const FilesApi().deleteAll(actualFiles);

    posts.downloadAll();
  } catch (e) {
    // TODO: add scaffold
    //   ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    //     SnackBar(
    //       content: Text(l10n.redownloadInProgress),
    //     ),
    //   );
  } finally {
    for (final client in clients.values) {
      client.close();
    }

    progress?.done();
  }
}

class SetWallpaperChip extends StatelessWidget {
  const SetWallpaperChip({
    super.key,
    required this.id,
  });

  final int id;

  Future<void> setWallpaper() async {
    try {
      await const AppApi().setWallpaper(id);
    } catch (e, trace) {
      Logger.root.warning("setWallpaper", e, trace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    final task = const TasksService().status<SetWallpaperChip>(context);

    return ActionChip(
      onPressed: task.isWaiting
          ? null
          : () => const TasksService().add<SetWallpaperChip>(setWallpaper),
      label: task.isWaiting
          ? const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.setAsWallpaper),
      avatar: const Icon(
        Icons.wallpaper_rounded,
        size: 18,
      ),
    );
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/services/local_tags_helper.dart";
import "package:azari/src/services/obj_impls/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
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
    required this.downloadManager,
    required this.localTags,
    required this.settingsService,
    required this.galleryService,
  });

  final bool hasTranslation;

  final File file;
  final ImageViewTags tags;

  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;

  final GalleryService galleryService;
  final SettingsService settingsService;

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
              galleryService: galleryService,
              downloadManager: downloadManager,
              localTags: localTags,
              settingsService: settingsService,
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

class RedownloadChip extends StatefulWidget {
  const RedownloadChip({
    super.key,
    required this.file,
    required this.res,
    required this.downloadManager,
    required this.localTags,
    required this.settingsService,
    required this.galleryService,
  });

  final File file;
  final ParsedFilenameResult? res;

  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;

  final GalleryService galleryService;
  final SettingsService settingsService;

  @override
  State<RedownloadChip> createState() => _RedownloadChipState();
}

class _RedownloadChipState extends State<RedownloadChip> {
  DownloadManager? get downloadManager => widget.downloadManager;
  LocalTagsService? get localTags => widget.localTags;

  GalleryService get galleryService => widget.galleryService;

  SettingsService get settingsService => widget.settingsService;

  ValueNotifier<Future<void>?>? notifier;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (notifier == null) {
      notifier = GlobalProgressTab.maybeOf(context)?.redownloadFiles();

      notifier?.addListener(listener);
    }
  }

  void listener() {
    setState(() {});
  }

  @override
  void dispose() {
    notifier?.removeListener(listener);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ActionChip(
      onPressed: notifier == null ||
              notifier?.value != null ||
              downloadManager == null ||
              localTags == null
          ? null
          : () {
              redownloadFiles(
                context,
                [widget.file],
                downloadManager: downloadManager!,
                localTags: localTags!,
                galleryService: galleryService,
                settingsService: settingsService,
              );
            },
      label: Text(l10n.redownloadLabel),
      avatar: const Icon(
        Icons.download_outlined,
        size: 18,
      ),
    );
  }
}

extension RedownloadFilesGlobalNotifier on GlobalProgressTab {
  ValueNotifier<Future<void>?> redownloadFiles() {
    return get("redownloadFiles", () => ValueNotifier(null));
  }
}

Future<void> redownloadFiles(
  BuildContext context,
  List<File> files, {
  required DownloadManager downloadManager,
  required LocalTagsService localTags,
  required GalleryService galleryService,
  required SettingsService settingsService,
}) {
  final l10n = context.l10n();

  final notifier = GlobalProgressTab.maybeOf(context)?.redownloadFiles();
  if (notifier == null) {
    return Future.value();
  } else if (notifier.value != null) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(l10n.redownloadInProgress),
      ),
    );

    return Future.value();
  }

  final clients = <Booru, Dio>{};
  final apis = <Booru, BooruAPI>{};

  final notif = NotificationApi().show(
    id: NotificationApi.redownloadFilesId,
    title: l10n.redownloadFetchingUrls,
    group: NotificationGroup.misc,
    channel: NotificationChannel.misc,
    body: l10n.redownloadRedowloadingFiles(files.length),
  );

  return notifier.value = Future(() async {
    final progress = await notif;
    progress.setTotal(files.length);

    final posts = <Post>[];
    final actualFiles = <File>[];

    for (final (index, file) in files.indexed) {
      progress.update(index, "$index / ${files.length}");

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

    galleryService.files.deleteAll(actualFiles);

    posts.downloadAll(
      downloadManager: downloadManager,
      localTags: localTags,
      settingsService: settingsService,
    );
  }).whenComplete(() {
    for (final client in clients.values) {
      client.close();
    }

    notif.then((v) {
      v.done();
    });

    notifier.value = null;
  });
}

class SetWallpaperChip extends StatefulWidget {
  const SetWallpaperChip({
    super.key,
    required this.id,
  });

  final int id;

  @override
  State<SetWallpaperChip> createState() => _SetWallpaperChipState();
}

class _SetWallpaperChipState extends State<SetWallpaperChip> {
  Future<void>? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ActionChip(
      onPressed: _status != null
          ? null
          : () {
              _status =
                  PlatformApi().setWallpaper(widget.id).onError((e, trace) {
                Logger.root.warning("setWallpaper", e, trace);
              }).whenComplete(() {
                _status = null;

                setState(() {});
              });

              setState(() {});
            },
      label: _status != null
          ? const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                year2023: false,
              ),
            )
          : Text(l10n.setAsWallpaper),
      avatar: const Icon(
        Icons.wallpaper_rounded,
        size: 18,
      ),
    );
  }
}

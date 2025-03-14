// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/services/local_tags_helper.dart";
import "package:azari/src/db/services/obj_impls/file_impl.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/platform/gallery_file_functions.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/file_action_chips.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/load_tags.dart";
import "package:azari/src/widgets/post_info.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class FileInfo extends StatefulWidget {
  const FileInfo({
    super.key,
    required this.file,
    required this.tags,
    required this.tagManager,
    required this.localTags,
    required this.settingsService,
    required this.downloadManager,
    required this.galleryService,
  });

  final File file;
  final ImageViewTags tags;

  final TagManagerService? tagManager;
  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;

  final GalleryService galleryService;
  final SettingsService settingsService;

  @override
  State<FileInfo> createState() => _FileInfoState();
}

class _FileInfoState extends State<FileInfo> {
  TagManagerService? get tagManager => widget.tagManager;
  DownloadManager? get downloadManager => widget.downloadManager;
  LocalTagsService? get localTags => widget.localTags;

  GalleryService get galleryService => widget.galleryService;
  SettingsService get settingsService => widget.settingsService;

  File get file => widget.file;
  ImageViewTags get tags => widget.tags;

  late final StreamSubscription<void> events;

  bool hasTranslation = false;

  late final bool filesExtended;

  @override
  void initState() {
    super.initState();

    filesExtended = widget.settingsService.current.filesExtendedActions;

    if (tags.list.indexWhere((e) => e.tag == "translated") != -1) {
      hasTranslation = true;
    }

    events = widget.tags.stream.listen((_) {
      if (tags.list.indexWhere((e) => e.tag == "translated") != -1) {
        hasTranslation = true;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  void _launchGrid(BuildContext context, String t, [SafeMode? safeMode]) {
    OnBooruTagPressed.pressOf(
      context,
      t,
      tags.res!.booru,
      overrideSafeMode: safeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filename = file.name;

    final l10n = context.l10n();
    // final tagManager = TagManagerService.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: TagsRibbon(
            tagNotifier: ImageTagsNotifier.of(context),
            sliver: false,
            emptyWidget: tags.res == null
                ? const Padding(padding: EdgeInsets.zero)
                : LoadTags(
                    filename: filename,
                    res: tags.res!,
                    localTags: localTags,
                    galleryService: galleryService,
                  ),
            selectTag: !GlobalProgressTab.presentInScope(context)
                ? null
                : (str, controller) {
                    HapticFeedback.mediumImpact();

                    _launchGrid(context, str);
                  },
            tagManager: tagManager,
            showPin: false,
            items: (tag, controller) => [
              PopupMenuItem(
                onTap: tagManager != null
                    ? () {
                        if (tagManager!.pinned.exists(tag)) {
                          tagManager!.pinned.delete(tag);
                        } else {
                          tagManager!.pinned.add(tag);
                        }

                        ImageViewInfoTilesRefreshNotifier.refreshOf(context);

                        controller.animateTo(
                          0,
                          duration: Durations.medium3,
                          curve: Easing.standard,
                        );
                      }
                    : null,
                child: Text(
                  (tagManager?.pinned.exists(tag) ?? false)
                      ? l10n.unpinTag
                      : l10n.pinTag,
                ),
              ),
              if (GlobalProgressTab.presentInScope(context))
                launchGridSafeModeItem(
                  context,
                  tag,
                  _launchGrid,
                  l10n,
                  settingsService: settingsService,
                ),
              PopupMenuItem(
                onTap: tagManager != null
                    ? () {
                        if (tagManager!.excluded.exists(tag)) {
                          tagManager!.excluded.delete(tag);
                        } else {
                          tagManager!.excluded.add(tag);
                        }
                      }
                    : null,
                child: Text(
                  (tagManager?.excluded.exists(tag) ?? false)
                      ? l10n.removeFromExcluded
                      : l10n.addToExcluded,
                ),
              ),
            ],
          ),
        ),
        ListBody(
          children: [
            DimensionsName(
              l10n: l10n,
              width: file.width,
              height: file.height,
              name: file.name,
              icon: file.isVideo
                  ? const Icon(Icons.slideshow_outlined)
                  : const Icon(Icons.photo_outlined),
              onTap: () {
                Navigator.push<void>(
                  context,
                  DialogRoute(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(l10n.enterNewNameTitle),
                        content: TextFormField(
                          autofocus: true,
                          initialValue: filename,
                          autovalidateMode: AutovalidateMode.always,
                          decoration: const InputDecoration(
                            errorMaxLines: 2,
                          ),
                          validator: (value) {
                            if (value == null) {
                              return l10n.valueIsNull;
                            }

                            final res = ParsedFilenameResult.fromFilename(
                              value,
                            );
                            if (res.hasError) {
                              return res.asError(l10n);
                            }

                            return null;
                          },
                          onFieldSubmitted: (value) {
                            galleryService.files
                                .rename(file.originalUri, value);

                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              onLongTap: () {
                Clipboard.setData(ClipboardData(text: file.name));
              },
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
            if (file.res != null) FileBooruInfoTile(res: file.res!),
            FileInfoTile(file: file),
            const Padding(padding: EdgeInsets.only(top: 4)),
            const Divider(indent: 24, endIndent: 24),
            FileActionChips(
              file: file,
              tags: tags,
              hasTranslation: hasTranslation,
              downloadManager: downloadManager,
              localTags: localTags,
              galleryService: galleryService,
              settingsService: settingsService,
            ),
          ],
        ),
      ],
    );
  }
}

class FileBooruInfoTile extends StatelessWidget {
  const FileBooruInfoTile({
    super.key,
    required this.res,
  });

  final (int, Booru) res;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasNotifiers = GlobalProgressTab.presentInScope(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        onTap: !hasNotifiers
            ? null
            : () {
                Navigator.pop(context);

                Post.imageViewSingle(context, res.$2, res.$1);
              },
        tileColor: theme.colorScheme.surfaceContainerHigh,
        leading: const Icon(Icons.description_outlined),
        title: Text(res.$2.string),
        subtitle: Text(res.$1.toString()),
      ),
    );
  }
}

class FileInfoTile extends StatelessWidget {
  const FileInfoTile({
    super.key,
    required this.file,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(15),
        bottomRight: Radius.circular(15),
      ),
    ),
  });

  final FileImpl file;

  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        shape: shape,
        tileColor: theme.colorScheme.surfaceContainerHigh,
        leading: const Icon(Icons.description_outlined),
        title: Text(kbMbSize(context, file.size)),
        subtitle: Text(
          l10n.date(
            DateTime.fromMillisecondsSinceEpoch(
              file.lastModified * 1000,
            ),
          ),
        ),
      ),
    );
  }
}

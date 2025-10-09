// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/obj/file_impl.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/home/booru_page.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/load_tags.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import "package:url_launcher/url_launcher.dart" as url;

class FileInfo extends StatefulWidget {
  const FileInfo({super.key, required this.file, required this.tags});

  final File file;
  final ImageViewTags tags;

  @override
  State<FileInfo> createState() => _FileInfoState();
}

class _FileInfoState extends State<FileInfo> {
  File get file => widget.file;
  ImageViewTags get tags => widget.tags;

  late final StreamSubscription<void> events;

  bool hasTranslation = false;

  late final bool filesExtended;

  @override
  void initState() {
    super.initState();

    filesExtended = const SettingsService().current.filesExtendedActions;

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
      file.res!.$2,
      overrideSafeMode: safeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filename = file.name;

    final l10n = context.l10n();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.only(top: 18)),
          if (TagManagerService.available)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TagsRibbon(
                tagNotifier: widget.tags,
                sliver: false,
                emptyWidget: file.res == null
                    ? const Padding(padding: EdgeInsets.zero)
                    : LoadTags(
                        filename: filename,
                        res: file.res!,
                        // galleryApi: ,
                      ),
                selectTag: (str, controller) {
                  HapticFeedback.mediumImpact();
                  ExitOnPressRoute.maybeExitOf(context);

                  _launchGrid(context, str);
                },
                showPin: false,
                items: (tag, controller) => [
                  PopupMenuItem(
                    onTap: TagManagerService.available
                        ? () {
                            const tagManager = TagManagerService();

                            if (tagManager.pinned.exists(tag)) {
                              tagManager.pinned.delete(tag);
                            } else {
                              tagManager.pinned.add(tag);
                            }

                            ImageViewInfoTilesRefreshNotifier.refreshOf(
                              context,
                            );

                            controller.animateTo(
                              0,
                              duration: Durations.medium3,
                              curve: Easing.standard,
                            );
                          }
                        : null,
                    child: Text(
                      (TagManagerService.safe()?.pinned.exists(tag) ?? false)
                          ? l10n.unpinTag
                          : l10n.pinTag,
                    ),
                  ),
                  launchGridSafeModeItem(context, tag, _launchGrid, l10n),
                  PopupMenuItem(
                    onTap: TagManagerService.available
                        ? () {
                            const tagManager = TagManagerService();

                            if (tagManager.excluded.exists(tag)) {
                              tagManager.excluded.delete(tag);
                            } else {
                              tagManager.excluded.add(tag);
                            }
                          }
                        : null,
                    child: Text(
                      (TagManagerService.safe()?.excluded.exists(tag) ?? false)
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
                            enabled: FilesApi.available,
                            decoration: const InputDecoration(errorMaxLines: 2),
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
                              const FilesApi().rename(file.originalUri, value);

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
              FileActionChips(file: file, hasTranslation: hasTranslation),
            ],
          ),
        ],
      ),
    );
  }
}

class FileActionChips extends StatelessWidget {
  const FileActionChips({
    super.key,
    required this.file,
    required this.hasTranslation,
  });

  final bool hasTranslation;

  final File file;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (file.res != null)
            RedownloadChip(key: file.uniqueKey(), file: file),
          if (!file.isVideo && !file.isGif) SetWallpaperChip(id: file.id),
          if (file.res != null) ...[
            ActionChip(
              onPressed: () => const AppApi().shareMedia(
                file.res!.$2.browserLink(file.res!.$1).toString(),
              ),
              label: Text(l10n.shareLabel),
              avatar: const Icon(Icons.share_rounded, size: 18),
            ),
            ActionChip(
              onPressed: () => url.launchUrl(
                file.res!.$2.browserLink(file.res!.$1),
                mode: url.LaunchMode.externalApplication,
              ),
              label: Text(l10n.openOnBooru(file.res!.$2.string)),
              avatar: const Icon(Icons.open_in_new_rounded, size: 18),
            ),
          ],
          if (file.res != null && hasTranslation)
            TranslationNotesChip(postId: file.res!.$1, booru: file.res!.$2),
        ],
      ),
    );
  }
}

class RedownloadChip extends StatelessWidget {
  const RedownloadChip({super.key, required this.file});

  final File file;

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
      avatar: const Icon(Icons.download_outlined, size: 18),
    );
  }
}

class SetWallpaperChip extends StatelessWidget {
  const SetWallpaperChip({super.key, required this.id});

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
      avatar: const Icon(Icons.wallpaper_rounded, size: 18),
    );
  }
}

class FileBooruInfoTile extends StatelessWidget {
  const FileBooruInfoTile({super.key, required this.res});

  final (int, Booru) res;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        onTap: () {
          Navigator.pop(context);

          openPostAsync(context, booru: res.$2, postId: res.$1);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        shape: shape,
        tileColor: theme.colorScheme.surfaceContainerHigh,
        leading: const Icon(Icons.description_outlined),
        title: Text(kbMbSize(context, file.size)),
        subtitle: FileInfoSubtitle(file: file),
      ),
    );
  }
}

class FileInfoSubtitle extends StatefulWidget {
  const FileInfoSubtitle({super.key, required this.file});

  final FileImpl file;

  @override
  State<FileInfoSubtitle> createState() => _FileInfoSubtitleState();
}

class _FileInfoSubtitleState extends State<FileInfoSubtitle>
    with FavoritePostSourceService, FavoritePostsWatcherMixin {
  late FavoritePost? post;

  @override
  void onFavoritePostsUpdate() {
    super.onFavoritePostsUpdate();

    if (widget.file.res != null) {
      post = cache.get((widget.file.res!.$1, widget.file.res!.$2));
    } else {
      post = null;
    }
  }

  @override
  void initState() {
    super.initState();

    onFavoritePostsUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text:
                "${l10n.date(DateTime.fromMillisecondsSinceEpoch(widget.file.lastModified * 1000))} ${post != null ? "\n" : ""}",
          ),
          if (post != null)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FiveStarsButtonsRow(post: post!, color: null),
              ),
            ),
          if (post != null)
            WidgetSpan(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: FilteringColors.values
                      .map(
                        (e) => ColorCubeButton(
                          color: e.color,
                          onTap: () =>
                              post!.copyWith(filteringColors: e).maybeSave(),
                          size: 18,
                          selected: e == post!.filteringColors,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 2,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

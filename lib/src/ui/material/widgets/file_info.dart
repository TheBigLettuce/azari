// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/obj/file_impl.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/widgets/file_action_chips.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/load_tags.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class FileInfo extends StatefulWidget {
  const FileInfo({
    super.key,
    required this.file,
    required this.tags,
  });

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
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (TagManagerService.available)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
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
                                context);

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
                  launchGridSafeModeItem(
                    context,
                    tag,
                    _launchGrid,
                    l10n,
                  ),
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
              FileActionChips(
                file: file,
                hasTranslation: hasTranslation,
              ),
            ],
          ),
        ],
      ),
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

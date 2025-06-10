// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/obj/file_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/settings/radio_dialog.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/ui/material/widgets/post_cell.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/list_layout.dart";
import "package:azari/src/ui/material/widgets/shell/parts/sticker_widget.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class FileCell extends StatelessWidget {
  const FileCell({
    super.key,
    required this.file,
    required this.isList,
    required this.imageAlign,
    required this.hideName,
  });

  final FileImpl file;

  final bool isList;
  final bool hideName;

  final Alignment imageAlign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final alias = hideName ? null : file.title(l10n);

    final animate = PlayAnimations.maybeOf(context) ?? false;

    final thumbnail = file.thumbnail();

    final theme = Theme.of(context);

    final filteringData = ChainedFilter.maybeOf(context);

    return Animate(
      key: file.uniqueKey(),
      effects: animate ? const [FadeEffect(end: 1)] : null,
      child: switch (isList) {
        true => WrapSelection(
          limitedSize: true,
          onPressed: () => file.openImage(context),
          child: DefaultListTile(
            uniqueKey: file.uniqueKey(),
            thumbnail: thumbnail,
            title: alias,
          ),
        ),
        false => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(0.5),
                elevation: 0,
                color: theme.cardColor.withValues(alpha: 0),
                child: ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: WrapSelection(
                    onPressed: () => file.openImage(context),
                    child: Stack(
                      children: [
                        GridCellImage(
                          imageAlign: imageAlign,
                          thumbnail: thumbnail,
                          blur: false,
                        ),
                        FileCellStickers(file: file),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: VideoOrGifIcon(
                              uniqueKey: file.uniqueKey(),
                              type: file.isVideo
                                  ? PostContentType.video
                                  : file.isGif
                                  ? PostContentType.gif
                                  : PostContentType.none,
                            ),
                          ),
                        ),
                        if (alias != null && alias.isNotEmpty)
                          GridCellName(title: alias, lines: file.titleLines()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (LocalTagsService.available &&
                filteringData != null &&
                (filteringData.filteringMode == FilteringMode.tag ||
                    filteringData.filteringMode == FilteringMode.tagReversed))
              FileCellTagsList(file: file),
          ],
        ),
      },
    );
  }
}

class FileCellStickers extends StatefulWidget {
  const FileCellStickers({super.key, required this.file});

  final FileImpl file;

  @override
  State<FileCellStickers> createState() => _FileCellStickersState();
}

class _FileCellStickersState extends State<FileCellStickers>
    with FavoritePostsWatcherMixin {
  @override
  Widget build(BuildContext context) {
    final stickers = widget.file.stickers(context, false);

    if (stickers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          direction: Axis.vertical,
          children: stickers.map(StickerWidget.new).toList(),
        ),
      ),
    );
  }
}

class FileCellTagsList extends StatefulWidget {
  const FileCellTagsList({super.key, required this.file});

  final FileImpl file;

  @override
  State<FileCellTagsList> createState() => _FileCellTagsListState();
}

class _FileCellTagsListState extends State<FileCellTagsList>
    with PinnedSortedTagsArrayMixin, LocalTagsService {
  @override
  List<String> postTags = const [];

  @override
  void initState() {
    super.initState();

    final res = widget.file.res;
    if (res != null) {
      postTags = get(widget.file.name);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.file.res;

    if (res == null || postTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final (id, booru) = res;

    return SizedBox(
      height: 21,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ListView.builder(
          clipBehavior: Clip.antiAlias,
          scrollDirection: Axis.horizontal,
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final e = tags[index];

            return OutlinedTagChip(
              tag: e.tag,
              letterCount: 8,
              isPinned: e.pinned,
              onLongPressed: () {
                context.openSafeModeDialog((safeMode) {
                  OnBooruTagPressed.pressOf(
                    context,
                    e.tag,
                    booru,
                    overrideSafeMode: safeMode,
                  );
                });
              },
              onPressed: () => OnBooruTagPressed.pressOf(context, e.tag, booru),
            );
          },
        ),
      ),
    );
  }
}

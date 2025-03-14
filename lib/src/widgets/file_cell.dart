// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/obj_impls/file_impl.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/other/settings/radio_dialog.dart";
import "package:azari/src/widgets/grid_cell_widget.dart";
import "package:azari/src/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/widgets/post_info.dart";
import "package:azari/src/widgets/shell/parts/sticker_widget.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class FileCell extends StatelessWidget {
  const FileCell({
    super.key,
    required this.file,
    required this.isList,
    required this.hideTitle,
    required this.animated,
    required this.blur,
    required this.imageAlign,
    required this.wrapSelection,
    required this.localTags,
    required this.settingsService,
  });

  final FileImpl file;

  final bool isList;
  final bool hideTitle;
  final bool animated;
  final bool blur;
  final Alignment imageAlign;
  final Widget Function(Widget child) wrapSelection;

  final LocalTagsService? localTags;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final description = file.description();
    final alias = hideTitle ? "" : file.alias(isList);

    final stickers =
        description.ignoreStickers ? null : file.stickers(context, false);
    final thumbnail = file.thumbnail(context);

    final theme = Theme.of(context);

    final filteringData = ChainedFilter.maybeOf(context);

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Card(
            margin: description.tightMode ? const EdgeInsets.all(0.5) : null,
            elevation: 0,
            color: theme.cardColor.withValues(alpha: 0),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: description.circle
                    ? const CircleBorder()
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
              ),
              child: wrapSelection(
                Stack(
                  children: [
                    GridCellImage(
                      imageAlign: imageAlign,
                      thumbnail: thumbnail,
                      blur: blur,
                    ),
                    if (stickers != null && stickers.isNotEmpty)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            direction: Axis.vertical,
                            children: stickers.map(StickerWidget.new).toList(),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: VideoGifRow(
                          isVideo: file.isVideo,
                          isGif: file.isGif,
                        ),
                      ),
                    ),
                    if (alias.isNotEmpty)
                      GridCellName(
                        title: alias,
                        lines: description.titleLines,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (localTags != null &&
            filteringData != null &&
            (filteringData.filteringMode == FilteringMode.tag ||
                filteringData.filteringMode == FilteringMode.tagReversed))
          FileCellTagsList(
            file: file,
            localTags: localTags!,
            settingsService: settingsService,
          ),
      ],
    );

    if (animated) {
      child = child.animate(key: file.uniqueKey()).fadeIn();
    }

    return child;
  }
}

class FileCellTagsList extends StatefulWidget {
  const FileCellTagsList({
    super.key,
    required this.file,
    required this.localTags,
    required this.settingsService,
  });

  final FileImpl file;

  final LocalTagsService localTags;
  final SettingsService settingsService;

  @override
  State<FileCellTagsList> createState() => _FileCellTagsListState();
}

class _FileCellTagsListState extends State<FileCellTagsList>
    with PinnedSortedTagsArrayMixin {
  LocalTagsService get localTags => widget.localTags;

  @override
  List<String> postTags = const [];

  @override
  void initState() {
    super.initState();

    final res = widget.file.res;
    if (res != null) {
      postTags = localTags.get(widget.file.name);
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
                context.openSafeModeDialog(widget.settingsService, (safeMode) {
                  OnBooruTagPressed.pressOf(
                    context,
                    e.tag,
                    booru,
                    overrideSafeMode: safeMode,
                  );
                });
              },
              onPressed: () => OnBooruTagPressed.pressOf(
                context,
                e.tag,
                booru,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/post_tags.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";

class TagsListWidget extends StatefulWidget with DbConnHandle<TagManager> {
  const TagsListWidget(
    this.filename, {
    super.key,
    this.res,
    this.launchGrid,
    this.addRemoveTag = false,
    required this.db,
  });

  @override
  final TagManager db;
  final DisassembleResult? res;
  final String filename;
  final void Function(BuildContext, String, [SafeMode?])? launchGrid;
  final bool addRemoveTag;

  @override
  State<TagsListWidget> createState() => _TagsListWidgetState();
}

class _TagsListWidgetState extends State<TagsListWidget>
    with TagManagerDbScope<TagsListWidget> {
  late final StreamSubscription<void>? _watcher;

  @override
  void initState() {
    super.initState();

    _watcher = excluded.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _watcher?.cancel();

    super.dispose();
  }

  List<PopupMenuItem<void>> makeItems(
    BuildContext context,
    String tag,
    AppLocalizations l10n,
  ) {
    return [
      PopupMenuItem(
        onTap: () {
          if (excluded.exists(tag)) {
            excluded.delete(tag);
          } else {
            excluded.add(tag);
          }
        },
        child: Text(
          excluded.exists(tag) ? l10n.removeFromExcluded : l10n.addToExcluded,
        ),
      ),
      if (widget.launchGrid != null)
        launchGridSafeModeItem(
          context,
          tag,
          widget.launchGrid!,
          l10n,
        ),
      if (widget.addRemoveTag)
        PopupMenuItem(
          onTap: () {
            DatabaseConnectionNotifier.of(context)
                .localTags
                .removeSingle([widget.filename], tag);
          },
          child: Text(l10n.delete),
        ),
      PopupMenuItem(
        onTap: () {
          if (pinned.exists(tag)) {
            pinned.delete(tag);
          } else {
            pinned.add(tag);
          }

          ImageViewInfoTilesRefreshNotifier.refreshOf(context);
        },
        child: Text(pinned.exists(tag) ? l10n.unpinTag : l10n.pinTag),
      ),
    ];
  }

  Widget makeTile(
    BuildContext context,
    String e,
    bool pinned,
    AppLocalizations l10n,
  ) =>
      MenuWrapper(
        title: e,
        items: makeItems(context, e, l10n),
        child: RawChip(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          avatar: pinned ? const Icon(Icons.push_pin_rounded, size: 18) : null,
          label: Text(
            e,
            style: TextStyle(
              color: excluded.exists(e)
                  ? Colors.red
                      .harmonizeWith(Theme.of(context).colorScheme.primary)
                      .withOpacity(0.9)
                  : null,
            ),
          ),
          onPressed: widget.launchGrid == null
              ? null
              : () {
                  widget.launchGrid!(context, e);
                },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final filename = widget.filename;
    final res = widget.res;
    final tags = ImageTagsNotifier.of(context);

    if (tags.isEmpty) {
      if (filename.isEmpty) {
        return const SliverPadding(padding: EdgeInsets.zero);
      }

      return res == null
          ? const SliverPadding(padding: EdgeInsets.zero)
          : LoadTags(
              filename: filename,
              res: res,
            );
    }

    final value = TagFilterValueNotifier.maybeOf(context).trim();
    final data = TagFilterNotifier.maybeOf(context);

    final Iterable<ImageTag> filteredTags;
    if (data != null && value.isNotEmpty) {
      filteredTags = tags.where((element) => element.tag.contains(value));
    } else {
      filteredTags = tags;
    }

    final l10n = AppLocalizations.of(context)!;

    final tiles =
        filteredTags.map((e) => makeTile(context, e.tag, e.favorite, l10n));

    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      sliver: SliverToBoxAdapter(
        child: Wrap(
          spacing: 4,
          children: tiles.toList(),
        ),
      ),
    );
  }
}

class LoadTags extends StatelessWidget {
  const LoadTags({
    super.key,
    required this.res,
    required this.filename,
  });
  final DisassembleResult res;
  final String filename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SliverPadding(
      padding: const EdgeInsets.all(4),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              child: Text(l10n.loadTags),
            ),
            FilledButton(
              onPressed: TagRefreshNotifier.isRefreshingOf(context) ?? false
                  ? null
                  : () {
                      try {
                        final setIsRefreshing =
                            TagRefreshNotifier.setIsRefreshingOf(context);
                        setIsRefreshing?.call(true);

                        final notifier = TagRefreshNotifier.maybeOf(context);

                        final postTags = PostTags.fromContext(context);

                        postTags
                            .loadFromDissassemble(
                          filename,
                          res,
                          DatabaseConnectionNotifier.of(context)
                              .localTagDictionary,
                        )
                            .then((value) {
                          postTags.addTagsPost(filename, value, true);
                          notifier?.call();
                          chooseGalleryPlug().notify(null);
                        }).whenComplete(() => setIsRefreshing?.call(false));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.notValidFilename(e.toString())),
                          ),
                        );
                      }
                    },
              child: TagRefreshNotifier.isRefreshingOf(context) ?? false
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text("From ${res.booru.string}"),
            ),
          ],
        ),
      ),
    );
  }
}

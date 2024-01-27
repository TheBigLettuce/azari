// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/tags/pinned_tag.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:gallery/src/interfaces/booru_tagging.dart';
import 'package:gallery/src/widgets/notifiers/image_view_info_tiles_refresh_notifier.dart';
import 'package:gallery/src/widgets/settings_label.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../db/tags/post_tags.dart';
import '../interfaces/cell/cell.dart';
import '../plugs/platform_fullscreens.dart';
import 'load_tags.dart';
import 'notifiers/filter.dart';
import 'notifiers/filter_value.dart';

Iterable<Widget> makeTags(
  BuildContext context,
  dynamic extra,
  AddInfoColorData colors,
  List<String> tags,
  String filename, {
  required List<String> pinnedTags,
  void Function(String)? launchGrid,
  BooruTagging? excluded,
}) {
  if (tags.isEmpty) {
    if (filename.isEmpty) {
      return [Container()];
    }
    DisassembleResult? res;
    try {
      res = PostTags.g.dissassembleFilename(filename);
    } catch (_) {}

    return [
      LoadTags(
        filename: filename,
        res: res,
      )
    ];
  }
  final plug = choosePlatformFullscreenPlug(colors.systemOverlayColor);
  final value = FilterValueNotifier.maybeOf(context).trim();
  final data = FilterNotifier.maybeOf(context);

  final List<String> filteredTags;
  if (data != null && value.isNotEmpty) {
    filteredTags = tags.where((element) => element.contains(value)).toList();
  } else {
    filteredTags = tags;
  }

  return [
    SettingsLabel(
        AppLocalizations.of(context)!.tagsInfoPage,
        Theme.of(context)
            .textTheme
            .titleSmall!
            .copyWith(color: colors.foregroundColor)),
    if (pinnedTags.isNotEmpty)
      ...ListTile.divideTiles(
          color: colors.borderColor,
          tiles: pinnedTags.map(
            (e) => _MenuAnchor(
              excluded: excluded,
              tag: e,
              child: ListTile(
                textColor: colors.foregroundColor,
                trailing: Icon(
                  Icons.push_pin_rounded,
                  color: colors.foregroundColor.withOpacity(0.6),
                  size: 18,
                ),
                title: Text(HtmlUnescape().convert(e)),
                onTap: launchGrid == null
                    ? null
                    : () {
                        launchGrid(e);
                        plug.unfullscreen();
                        extra();
                      },
              ),
            ),
          )),
    ...ListTile.divideTiles(
        color: colors.borderColor,
        tiles: filteredTags.map(
          (e) => _MenuAnchor(
            excluded: excluded,
            tag: e,
            child: ListTile(
              textColor: colors.foregroundColor,
              title: Text(HtmlUnescape().convert(e)),
              onTap: launchGrid == null
                  ? null
                  : () {
                      launchGrid(e);
                      plug.unfullscreen();
                      extra();
                    },
            ),
          ),
        ))
  ];
}

class _MenuAnchor extends StatefulWidget {
  final String tag;
  final BooruTagging? excluded;
  final Widget child;

  const _MenuAnchor({
    super.key,
    required this.excluded,
    required this.tag,
    required this.child,
  });

  @override
  State<_MenuAnchor> createState() => __MenuAnchorState();
}

class __MenuAnchorState extends State<_MenuAnchor> {
  final controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        final RenderBox overlay = Navigator.of(context)
            .overlay!
            .context
            .findRenderObject()! as RenderBox;

        final t = Tag.string(tag: widget.tag);

        showMenu(
            clipBehavior: Clip.antiAlias,
            constraints:
                const BoxConstraints(minWidth: 56 * 3, maxWidth: 56 * 3),
            context: context,
            position: RelativeRect.fromRect(
              Rect.fromPoints(
                details.globalPosition + const Offset(0, 8),
                details.globalPosition + const Offset(((56 * 3) / 2) + 8, 0),
              ),
              Offset.zero & overlay.size,
            ),
            items: [
              PopupMenuItem(
                enabled: false,
                child: Center(
                  child: SettingsLabel(
                    removePadding: true,
                    widget.tag,
                    SettingsLabel.defaultStyle(context),
                  ),
                ),
              ),
              if (widget.excluded != null)
                PopupMenuItem(
                  onTap: () {
                    if (widget.excluded!.exists(t)) {
                      widget.excluded!.delete(t);
                    } else {
                      widget.excluded!.add(t);
                    }
                  },
                  child: Text(widget.excluded!.exists(t)
                      ? "Remove from excluded"
                      : "Add to excluded"),
                ),
              PopupMenuItem(
                onTap: () {
                  if (PinnedTag.isPinned(widget.tag)) {
                    PinnedTag.remove(widget.tag);
                  } else {
                    PinnedTag.add(widget.tag);
                  }

                  ImageViewInfoTilesRefreshNotifier.refreshOf(context);
                },
                child: Text(PinnedTag.isPinned(widget.tag) ? "Unpin" : "Pin"),
              ),
            ]);
      },
      child: widget.child,
    );
  }
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/make_tags.dart';
import 'package:gallery/src/widgets/menu_wrapper.dart';

import '../../../db/schemas/tags/tags.dart';
import '../../../widgets/empty_widget.dart';
import '../../../widgets/time_label.dart';

class TagsWidget extends StatelessWidget {
  final void Function(Tag tag) deleteTag;
  final void Function(Tag tag, SafeMode? safeMode)? onPress;
  final bool redBackground;
  final List<Tag> tags;
  final Widget searchBar;

  const TagsWidget({
    super.key,
    required this.tags,
    required this.searchBar,
    this.redBackground = false,
    required this.deleteTag,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final listWraps = <Widget>[
      Padding(
        padding:
            const EdgeInsets.only(bottom: 10, left: 10, right: 10, top: 10),
        child: searchBar,
      )
    ];
    final list = <Widget>[];
    final timeNow = DateTime.now();

    if (tags.isEmpty) {
      return SliverList.list(
        children: [
          ...listWraps,
          const Center(
              child: EmptyWidget(
            gridSeed: 0,
          ))
        ],
      );
    }

    (int, int, int)? time;

    final titleStyle = Theme.of(context)
        .textTheme
        .titleSmall!
        .copyWith(color: Theme.of(context).colorScheme.secondary);

    for (final e in tags) {
      if (time == null) {
        time = (e.time.day, e.time.month, e.time.year);
      } else if (time != (e.time.day, e.time.month, e.time.year)) {
        listWraps.add(TimeLabel(time, titleStyle, timeNow));
        listWraps.add(Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Wrap(
            children: list.map((e) => e).toList(),
          ),
        ));

        time = (e.time.day, e.time.month, e.time.year);

        list.clear();
      }

      list.add(SingleTagWidget(
        onPress: onPress,
        tag: e,
        redBackground: redBackground,
        deleteTag: deleteTag,
      ));
    }

    if (list.isNotEmpty) {
      final t = tags.last.time;
      listWraps.add(TimeLabel((t.day, t.month, t.year), titleStyle, timeNow));
      listWraps.add(Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Wrap(
          children: list.map((e) => e).toList(),
        ),
      ));
    }

    return SliverList.list(children: listWraps);
  }
}

class SingleTagWidget extends StatelessWidget {
  final Tag tag;
  final void Function(Tag tag) deleteTag;
  final bool redBackground;
  final void Function(Tag tag, SafeMode? safeMode)? onPress;

  const SingleTagWidget({
    super.key,
    required this.tag,
    required this.deleteTag,
    required this.onPress,
    required this.redBackground,
  });

  @override
  Widget build(BuildContext context) {
    WrapSelection;
    return MenuWrapper(
      title: tag.tag,
      items: [
        if (onPress != null)
          launchGridSafeModeItem(
            context,
            tag.tag,
            (context, _, [safeMode]) {
              onPress!(tag, safeMode);
            },
          ),
        PopupMenuItem(
          onTap: () {
            deleteTag(tag);
          },
          child: const Text("Delete"), // TODO: change
        )
      ],
      child: RawChip(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        side: redBackground ? BorderSide(color: Colors.pink.shade200) : null,
        backgroundColor: redBackground ? Colors.pink : null,
        label: Text(tag.tag,
            style: redBackground
                ? TextStyle(color: Colors.white.withOpacity(0.8))
                : null),
        onPressed: onPress == null
            ? null
            : () {
                onPress!(tag, null);
              },
      ),
    );
  }
}

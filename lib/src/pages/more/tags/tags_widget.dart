// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/booru_tagging.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/make_tags.dart';
import 'package:gallery/src/widgets/menu_wrapper.dart';

import '../../../db/schemas/tags/tags.dart';

class TagsWidget extends StatefulWidget {
  final void Function(Tag tag, SafeMode? safeMode)? onPress;
  final bool redBackground;
  final BooruTagging tagging;

  const TagsWidget({
    super.key,
    this.redBackground = false,
    required this.tagging,
    required this.onPress,
  });

  @override
  State<TagsWidget> createState() => _TagsWidgetState();
}

class _TagsWidgetState extends State<TagsWidget> {
  late final StreamSubscription<void> watcher;
  late final List<Tag> _tags = widget.tagging.get(30);
  int refreshes = 0;

  @override
  void initState() {
    super.initState();

    watcher = widget.tagging.watch((_) {
      _tags.clear();

      _tags.addAll(widget.tagging.get(30));

      setState(() {
        refreshes += 1;
      });
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 2),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          key: ValueKey(refreshes),
          itemCount: _tags.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: SingleTagWidget(
                tag: _tags[index],
                tagging: widget.tagging,
                onPress: widget.onPress,
                redBackground: widget.redBackground,
              ),
            );
          },
        ),
      ),
    );
  }
}

class SingleTagWidget extends StatelessWidget {
  final Tag tag;
  final BooruTagging tagging;
  final bool redBackground;
  final void Function(Tag tag, SafeMode? safeMode)? onPress;

  const SingleTagWidget({
    super.key,
    required this.tag,
    required this.onPress,
    required this.tagging,
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
            tagging.delete(tag);
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
                tagging.add(tag);
                onPress!(tag, null);
              },
      ),
    );
  }
}

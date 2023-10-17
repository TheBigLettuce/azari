// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/schemas/tags.dart';
import 'empty_widget.dart';
import 'time_label.dart';

class TagsWidget extends StatelessWidget {
  final void Function(Tag tag) deleteTag;
  final void Function(Tag tag)? onPress;
  final bool redBackground;
  final List<Tag> tags;
  final Widget searchBar;

  const TagsWidget(
      {super.key,
      required this.tags,
      required this.searchBar,
      this.redBackground = false,
      required this.deleteTag,
      required this.onPress});

  Widget _make(BuildContext context) {
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
      return Column(
        children: [
          ...listWraps,
          const Expanded(child: Center(child: EmptyWidget()))
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
        listWraps.add(timeLabel(time, titleStyle, timeNow));
        listWraps.add(Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Wrap(
            children: list.map((e) => e).toList(),
          ),
        ));

        time = (e.time.day, e.time.month, e.time.year);

        list.clear();
      }

      list.add(GestureDetector(
        onLongPress: () {
          HapticFeedback.vibrate();
          Navigator.of(context).push(DialogRoute(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text(
                        AppLocalizations.of(context)!.tagDeleteDialogTitle),
                    content: Text(e.tag),
                    actions: [
                      TextButton(
                          onPressed: () {
                            deleteTag(e);
                            Navigator.of(context).pop();
                          },
                          child: Text(AppLocalizations.of(context)!.yes))
                    ],
                  )));
        },
        child: ActionChip(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          side: redBackground ? BorderSide(color: Colors.pink.shade200) : null,
          backgroundColor: redBackground ? Colors.pink : null,
          label: Text(e.tag,
              style: redBackground
                  ? TextStyle(color: Colors.white.withOpacity(0.8))
                  : null),
          onPressed: onPress == null
              ? null
              : () {
                  onPress!(e);
                },
        ),
      ));
    }

    if (list.isNotEmpty) {
      final t = tags.last.time;
      listWraps.add(timeLabel((t.day, t.month, t.year), titleStyle, timeNow));
      listWraps.add(Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Wrap(
          children: list.map((e) => e).toList(),
        ),
      ));
    }

    return ListView(children: listWraps);
  }

  @override
  Widget build(BuildContext context) {
    return _make(context);
  }
}

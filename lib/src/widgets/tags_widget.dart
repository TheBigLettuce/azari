// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../schemas/tags.dart';
import 'empty_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: searchBar,
          ),
          tags.isEmpty
              ? const EmptyWidget()
              : Wrap(
                  children: tags.map((tag) {
                    return GestureDetector(
                      onLongPress: () {
                        HapticFeedback.vibrate();
                        Navigator.of(context).push(DialogRoute(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: Text(AppLocalizations.of(context)!
                                      .tagDeleteDialogTitle),
                                  content: Text(tag.tag),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          deleteTag(tag);
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                            AppLocalizations.of(context)!.yes))
                                  ],
                                )));
                      },
                      child: ActionChip(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                        side: redBackground
                            ? BorderSide(color: Colors.pink.shade200)
                            : null,
                        backgroundColor: redBackground ? Colors.pink : null,
                        label: Text(tag.tag,
                            style: redBackground
                                ? TextStyle(
                                    color: Colors.white.withOpacity(0.8))
                                : null),
                        onPressed: onPress == null
                            ? null
                            : () {
                                onPress!(tag);
                              },
                      ),
                    );
                  }).toList(),
                )
        ],
      ),
    );
  }
}

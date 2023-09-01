// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/settings_label.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../booru/tags/tags.dart';
import '../cell/cell.dart';
import '../plugs/platform_fullscreens.dart';
import 'booru/autocomplete_tag.dart';
import 'load_tags.dart';

Iterable<Widget> makeTags(
  BuildContext context,
  dynamic extra,
  AddInfoColorData colors,
  List<String> tags,
  String filename, {
  void Function(String)? launchGrid,
  void Function(String)? addExcluded,
}) {
  if (tags.isEmpty) {
    if (filename.isEmpty) {
      return [Container()];
    }
    DissolveResult? res;
    try {
      res = PostTags().dissassembleFilename(filename);
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
    settingsLabel(
        AppLocalizations.of(context)!.tagsInfoPage,
        Theme.of(context)
            .textTheme
            .titleSmall!
            .copyWith(color: Theme.of(context).colorScheme.secondary)),
    ...ListTile.divideTiles(
        color: colors.borderColor,
        tiles: filteredTags.map((e) => ListTile(
              textColor: colors.foregroundColor,
              title: Text(HtmlUnescape().convert(e)),
              onLongPress: addExcluded == null
                  ? null
                  : () {
                      Navigator.push(
                          context,
                          DialogRoute(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)!
                                      .addTagToExcluded),
                                  content: Text(e),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                            AppLocalizations.of(context)!.no)),
                                    TextButton(
                                        onPressed: () {
                                          addExcluded(e);
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                            AppLocalizations.of(context)!.yes))
                                  ],
                                );
                              }));
                    },
              onTap: launchGrid == null
                  ? null
                  : () {
                      launchGrid(e);
                      plug.unFullscreen();
                      extra();
                    },
            )))
  ];
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/tags/pinned_tag.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/booru_tagging.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/widgets/make_tags.dart';
import 'package:gallery/src/widgets/notifiers/filter.dart';
import 'package:gallery/src/widgets/search_bar/search_text_field.dart';
import 'package:gallery/src/widgets/translation_notes.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

mixin BooruPostFunctionalityMixin {
  void showQr(BuildContext context, String prefix, int id) {
    Navigator.push(
        context,
        DialogRoute(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                width: 320,
                height: 320,
                clipBehavior: Clip.antiAlias,
                child: QrImageView(
                  data: "${prefix}_$id",
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  version: QrVersions.auto,
                  size: 320,
                ),
              ),
            );
          },
        ));
  }

  Widget openInBrowserButton(Uri uri, [void Function()? overrideOnPressed]) =>
      IconButton(
        icon: const Icon(Icons.public),
        onPressed: overrideOnPressed ??
            () => launchUrl(uri, mode: LaunchMode.externalApplication),
      );

  Widget shareButton(BuildContext context, String url,
          [void Function()? onLongPress]) =>
      GestureDetector(
        onLongPress: onLongPress,
        child: IconButton(
            onPressed: () {
              PlatformFunctions.shareMedia(url, url: true);
            },
            icon: const Icon(Icons.share)),
      );

  List<(IconData, void Function()?)> defaultStickers(
    Contentable content,
    BuildContext? context,
    List<String> tags,
    int postId,
    Booru booru,
  ) {
    return [
      if (content is NetVideo) (FilteringMode.video.icon, null),
      if (content is NetGif) (FilteringMode.gif.icon, null),
      if (tags.contains("original")) (FilteringMode.original.icon, null),
      if (tags.contains("translated"))
        (
          Icons.translate_outlined,
          context == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    DialogRoute(
                      context: context,
                      builder: (context) {
                        return TranslationNotes(
                          postId: postId,
                          booru: booru,
                        );
                      },
                    ),
                  );
                }
        )
    ];
  }
}

List<Widget> wrapTagsList(
  BuildContext context,
  List<Widget> lists,
  String filename, {
  bool showDeleteButton = false,
  List<String>? supplyTags,
  void Function(BuildContext, String, [SafeMode?])? launchGrid,
  BooruTagging? excluded,
}) {
  final data = FilterNotifier.maybeOf(context);
  final pinnedTags = <String>[];
  final List<String> postTags;
  if (supplyTags == null) {
    postTags = PostTags.g.getTagsPost(filename);
  } else {
    postTags = supplyTags;
  }

  final tags = <String>[];

  for (final e in postTags) {
    if (PinnedTag.isPinned(e)) {
      pinnedTags.add(e);
    } else {
      tags.add(e);
    }
  }

  return [
    if (!(data?.searchFocus.hasFocus ?? false))
      ListBody(
        children: lists,
      ),
    if (postTags.isNotEmpty && data != null)
      SearchTextField(data, filename, showDeleteButton),
    ...makeTags(
      context,
      tags,
      filename,
      launchGrid: launchGrid,
      excluded: excluded,
      pinnedTags: pinnedTags,
    )
  ];
}

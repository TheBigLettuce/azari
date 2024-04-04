// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/db/schemas/tags/pinned_tag.dart';
import 'package:gallery/src/db/tags/booru_tagging.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'package:gallery/src/pages/booru/booru_page.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/widgets/make_tags.dart';
import 'package:gallery/src/widgets/menu_wrapper.dart';
import 'package:gallery/src/widgets/notifiers/filter.dart';
import 'package:gallery/src/widgets/search_bar/search_text_field.dart';
import 'package:gallery/src/widgets/translation_notes.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum PostContentType {
  none,
  video,
  gif,
  image;
}

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
    PostContentType type,
    BuildContext? context,
    List<String> tags,
    int postId,
    Booru booru,
  ) {
    return [
      if (type == PostContentType.video) (FilteringMode.video.icon, null),
      if (type == PostContentType.gif) (FilteringMode.gif.icon, null),
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

class PostInfo extends StatefulWidget {
  final PostBase post;

  const PostInfo({
    super.key,
    required this.post,
  });

  @override
  State<PostInfo> createState() => _PostInfoState();
}

class _PostInfoState extends State<PostInfo> {
  PostBase get post => widget.post;

  final settings = Settings.fromDb();

  late final tagManager = TagManager.fromEnum(post.booru);

  void _launchGrid(BuildContext context, String t, [SafeMode? safeMode]) {
    Navigator.pop(context);
    Navigator.pop(context);

    OnBooruTagPressed.pressOf(context, t, post.booru,
        overrideSafeMode: safeMode);
  }

  DisassembleResult? res;

  @override
  void initState() {
    super.initState();

    try {
      res = PostTags.g.dissassembleFilename(post.filename());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pinnedTags = <String>[];

    final tags = <String>[];

    for (final e in post.tags) {
      if (PinnedTag.isPinned(e)) {
        pinnedTags.add(e);
      } else {
        tags.add(e);
      }
    }

    final filename = post.filename();

    final filterData = FilterNotifier.maybeOf(context);

    return SliverMainAxisGroup(slivers: [
      if (!(filterData?.searchFocus.hasFocus ?? false))
        SliverList.list(
          children: [
            MenuWrapper(
              title: post.fileDownloadUrl(),
              child: ListTile(
                title: Text(AppLocalizations.of(context)!.urlInfoPage),
                subtitle: Text(post.fileDownloadUrl()),
                onTap: () => launchUrl(Uri.parse(post.fileDownloadUrl()),
                    mode: LaunchMode.externalApplication),
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.widthInfoPage),
              subtitle: Text(AppLocalizations.of(context)!.pixels(post.width)),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.heightInfoPage),
              subtitle: Text(AppLocalizations.of(context)!.pixels(post.height)),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.createdAtInfoPage),
              subtitle:
                  Text(AppLocalizations.of(context)!.date(post.createdAt)),
            ),
            MenuWrapper(
              title: post.sourceUrl,
              child: ListTile(
                title: Text(AppLocalizations.of(context)!.sourceFileInfoPage),
                subtitle: Text(post.sourceUrl),
                onTap: post.sourceUrl.isNotEmpty &&
                        Uri.tryParse(post.sourceUrl) != null
                    ? () => launchUrl(Uri.parse(post.sourceUrl),
                        mode: LaunchMode.externalApplication)
                    : null,
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.ratingInfoPage),
              subtitle: Text(post.rating.translatedName(context)),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.scoreInfoPage),
              subtitle: Text(post.score.toString()),
            ),
            if (tags.contains("translated"))
              TranslationNotes.tile(context, post.id, post.booru),
          ],
        ),
      if (tags.isNotEmpty && filterData != null)
        SliverToBoxAdapter(
          child: SearchTextField(
            filterData,
            filename,
            key: ValueKey(filename),
          ),
        ),
      DrawerTagsWidget(
        tags,
        filename,
        launchGrid: _launchGrid,
        excluded: tagManager.excluded,
        pinnedTags: pinnedTags,
        showTagButtons: false,
        res: res,
      )
    ]);
  }
}

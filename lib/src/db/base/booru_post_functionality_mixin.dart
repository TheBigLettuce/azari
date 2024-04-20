// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/db/schemas/tags/pinned_tag.dart';
import 'package:gallery/src/db/services/settings.dart';
import 'package:gallery/src/db/tags/booru_tagging.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'package:gallery/src/pages/booru/booru_page.dart';
import 'package:gallery/src/plugs/platform_functions.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart';
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
          themes: InheritedTheme.capture(from: context, to: null),
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
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

  List<Sticker> defaultStickers(
    PostContentType type,
    BuildContext? context,
    List<String> tags,
    int postId,
    Booru booru,
  ) {
    return [
      if (type == PostContentType.video) Sticker(FilteringMode.video.icon),
      if (type == PostContentType.gif) Sticker(FilteringMode.gif.icon),
      if (tags.contains("original")) Sticker(FilteringMode.original.icon),
      if (tags.contains("translated")) const Sticker(Icons.translate_outlined),
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
  int currentPage = 0;

  PostBase get post => widget.post;

  final settings = SettingsService.currentData;

  late final tagManager = TagManager.fromEnum(post.booru);

  void _launchGrid(BuildContext context, String t, [SafeMode? safeMode]) {
    OnBooruTagPressed.pressOf(context, t, post.booru,
        overrideSafeMode: safeMode);
  }

  DisassembleResult? res;

  @override
  void initState() {
    super.initState();

    res = PostTags.g.dissassembleFilename(post.filename()).maybeValue();
  }

  int currentPageF() => currentPage;

  void _switchPage(int i) {
    setState(() {
      currentPage = i;
    });
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
    final localizations = AppLocalizations.of(context)!;

    return SliverMainAxisGroup(slivers: [
      SliverPadding(
        padding: const EdgeInsets.only(left: 16),
        sliver: LabelSwitcherWidget(
          pages: [
            PageLabel(localizations.infoHeadline),
            PageLabel(localizations.tagsInfoPage, count: tags.length),
          ],
          currentPage: currentPageF,
          switchPage: _switchPage,
          sliver: true,
          noHorizontalPadding: true,
        ),
      ),
      if (currentPage == 0)
        SliverList.list(
          children: [
            MenuWrapper(
              title: post.fileDownloadUrl(),
              child: ListTile(
                title: Text(localizations.urlInfoPage),
                subtitle: Text(post.fileDownloadUrl()),
                onTap: () => launchUrl(Uri.parse(post.fileDownloadUrl()),
                    mode: LaunchMode.externalApplication),
              ),
            ),
            ListTile(
              title: Text(localizations.widthInfoPage),
              subtitle: Text(localizations.pixels(post.width)),
            ),
            ListTile(
              title: Text(localizations.heightInfoPage),
              subtitle: Text(localizations.pixels(post.height)),
            ),
            ListTile(
              title: Text(localizations.createdAtInfoPage),
              subtitle: Text(localizations.date(post.createdAt)),
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
              title: Text(localizations.ratingInfoPage),
              subtitle: Text(post.rating.translatedName(context)),
            ),
            ListTile(
              title: Text(localizations.scoreInfoPage),
              subtitle: Text(post.score.toString()),
            ),
            if (tags.contains("translated"))
              TranslationNotes.tile(context, post.id, post.booru),
          ],
        )
      else ...[
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
          res: res,
        )
      ]
    ]);
  }
}

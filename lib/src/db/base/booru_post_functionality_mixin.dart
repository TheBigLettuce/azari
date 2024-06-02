// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/base/post_base.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cell/sticker.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/make_tags.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";
import "package:gallery/src/widgets/search_bar/search_text_field.dart";
import "package:gallery/src/widgets/translation_notes.dart";
import "package:qr_flutter/qr_flutter.dart";
import "package:url_launcher/url_launcher.dart";

enum PostContentType {
  none,
  video,
  gif,
  image;
}

Future<void> showQr(BuildContext context, String prefix, int id) {
  return Navigator.push(
    context,
    DialogRoute<void>(
      themes: InheritedTheme.capture(from: context, to: null),
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

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
              backgroundColor: theme.colorScheme.onSurface,
              size: 320,
            ),
          ),
        );
      },
    ),
  );
}

class OpenInBrowserButton extends StatelessWidget {
  const OpenInBrowserButton(
    this.uri, {
    super.key,
    this.overrideOnPressed,
  });

  final Uri uri;
  final void Function()? overrideOnPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.public),
      onPressed: overrideOnPressed ??
          () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
  }
}

class ShareButton extends StatelessWidget {
  const ShareButton(
    this.url, {
    super.key,
    this.onLongPress,
  });

  final void Function()? onLongPress;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: IconButton(
        onPressed: () {
          PlatformApi.current().shareMedia(url, url: true);
        },
        icon: const Icon(Icons.share),
      ),
    );
  }
}

List<Sticker> defaultStickersPost(
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

class PostInfo extends StatefulWidget {
  const PostInfo({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  State<PostInfo> createState() => _PostInfoState();
}

class _PostInfoState extends State<PostInfo> {
  int currentPage = 0;

  Post get post => widget.post;

  final settings = SettingsService.db().current;

  void _launchGrid(BuildContext context, String t, [SafeMode? safeMode]) {
    OnBooruTagPressed.pressOf(
      context,
      t,
      post.booru,
      overrideSafeMode: safeMode,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  int currentPageF() => currentPage;

  void _switchPage(int i) {
    setState(() {
      currentPage = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filename = DisassembleResult.makeFilename(
      post.booru,
      post.fileDownloadUrl(),
      post.md5,
      post.id,
    );

    final l10n = AppLocalizations.of(context)!;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(left: 16),
          sliver: LabelSwitcherWidget(
            pages: [
              PageLabel(l10n.infoHeadline),
              PageLabel(
                l10n.tagsInfoPage,
                count: ImageTagsNotifier.of(context).length,
              ),
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
                  title: Text(l10n.urlInfoPage),
                  subtitle: Text(post.fileDownloadUrl()),
                  onTap: () => launchUrl(
                    Uri.parse(post.fileDownloadUrl()),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
              ListTile(
                title: Text(l10n.widthInfoPage),
                subtitle: Text(l10n.pixels(post.width)),
              ),
              ListTile(
                title: Text(l10n.heightInfoPage),
                subtitle: Text(l10n.pixels(post.height)),
              ),
              ListTile(
                title: Text(l10n.createdAtInfoPage),
                subtitle: Text(l10n.date(post.createdAt)),
              ),
              MenuWrapper(
                title: post.sourceUrl,
                child: ListTile(
                  title: Text(l10n.sourceFileInfoPage),
                  subtitle: Text(post.sourceUrl),
                  onTap: post.sourceUrl.isNotEmpty &&
                          Uri.tryParse(post.sourceUrl) != null
                      ? () => launchUrl(
                            Uri.parse(post.sourceUrl),
                            mode: LaunchMode.externalApplication,
                          )
                      : null,
                ),
              ),
              ListTile(
                title: Text(l10n.ratingInfoPage),
                subtitle: Text(post.rating.translatedName(l10n)),
              ),
              ListTile(
                title: Text(l10n.scoreInfoPage),
                subtitle: Text(post.score.toString()),
              ),
              if (post.tags.contains("translated"))
                TranslationNotes.tile(context, post.id, post.booru),
            ],
          )
        else ...[
          SliverToBoxAdapter(
            child: SearchTextField(
              filename,
              key: ValueKey(filename),
            ),
          ),
          DrawerTagsWidget(
            key: ValueKey(filename),
            filename,
            res: ImageTagsNotifier.resOf(context),
            launchGrid: _launchGrid,
            db: TagManager.of(context),
          ),
        ],
      ],
    );
  }
}

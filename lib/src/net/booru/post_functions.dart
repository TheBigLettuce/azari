// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/resource_source/filtering_mode.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/net/booru/booru.dart";
import "package:gallery/src/net/booru/post.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/translation_notes.dart";
import "package:url_launcher/url_launcher.dart";

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

  final PostImpl post;

  @override
  State<PostInfo> createState() => _PostInfoState();
}

class _PostInfoState extends State<PostInfo> {
  PostImpl get post => widget.post;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tagManager = TagManager.of(context);

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          sliver: TagsRibbon(
            selectTag: (str) {
              HapticFeedback.mediumImpact();

              _launchGrid(context, str);
            },
            tagManager: TagManager.of(context),
            showPin: false,
            items: (tag) => [
              PopupMenuItem(
                onTap: () {
                  if (tagManager.excluded.exists(tag)) {
                    tagManager.excluded.delete(tag);
                  } else {
                    tagManager.excluded.add(tag);
                  }
                },
                child: Text(
                  tagManager.excluded.exists(tag)
                      ? l10n.removeFromExcluded
                      : l10n.addToExcluded,
                ),
              ),
              launchGridSafeModeItem(
                context,
                tag,
                _launchGrid,
                l10n,
              ),
              PopupMenuItem(
                onTap: () {
                  if (tagManager.pinned.exists(tag)) {
                    tagManager.pinned.delete(tag);
                  } else {
                    tagManager.pinned.add(tag);
                  }

                  ImageViewInfoTilesRefreshNotifier.refreshOf(context);
                },
                child: Text(
                  tagManager.pinned.exists(tag) ? l10n.unpinTag : l10n.pinTag,
                ),
              ),
            ],
          ),
        ),
        SliverList.list(
          children: [
            DimensionsRow(
              l10n: l10n,
              width: post.width,
              height: post.height,
              createdAt: post.createdAt,
            ),
            ListTile(
              title: Center(
                child: Text(l10n.ratingInfoPage),
              ),
              subtitle: Center(
                child: Text(post.rating.translatedName(l10n)),
              ),
            ),
            ListTile(
              title: Center(
                child: Text(l10n.scoreInfoPage),
              ),
              subtitle: Center(
                child: Text(post.score.toString()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Wrap(
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(post.fileDownloadUrl()),
                      mode: LaunchMode.externalApplication,
                    ),
                    label: const Text("Link"),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: post.sourceUrl.isNotEmpty &&
                            Uri.tryParse(post.sourceUrl) != null
                        ? () => launchUrl(
                              Uri.parse(post.sourceUrl),
                              mode: LaunchMode.externalApplication,
                            )
                        : null,
                    label: const Text("Source"),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                    ),
                  ),
                  if (post.tags.contains("translated"))
                    TranslationNotes.button(context, post.id, post.booru),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DimensionsRow extends StatelessWidget {
  const DimensionsRow({
    super.key,
    required this.l10n,
    required this.width,
    required this.height,
    required this.createdAt,
  });

  final AppLocalizations l10n;

  final int width;
  final int height;

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ColoredRectangle(
              primaryColor: true,
              title: l10n.createdAtInfoPage,
              subtitle: l10n.date(createdAt),
            ),
            _ColoredRectangle(
              primaryColor: false,
              subtitle: l10n.pixels(width),
              title: l10n.widthInfoPage,
            ),
            _ColoredRectangle(
              primaryColor: false,
              subtitle: l10n.pixels(height),
              title: l10n.heightInfoPage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColoredRectangle extends StatelessWidget {
  const _ColoredRectangle({
    // super.key,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
  });

  final String title;
  final String subtitle;

  final bool primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: primaryColor
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.secondaryContainer,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  subtitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: primaryColor
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: primaryColor
                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                        : theme.colorScheme.onSecondaryContainer
                            .withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

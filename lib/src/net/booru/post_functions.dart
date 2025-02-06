// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/post.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/translation_notes.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:url_launcher/url_launcher.dart";

class OpenInBrowserButton extends StatelessWidget {
  const OpenInBrowserButton(
    this.uri, {
    super.key,
    this.overrideOnPressed,
  });

  final Uri uri;
  final VoidCallback? overrideOnPressed;

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

  final String url;

  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: IconButton(
        onPressed: () {
          PlatformApi().shareMedia(url, url: true);
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

class PostInfoSimple extends StatelessWidget {
  const PostInfoSimple({
    super.key,
    required this.post,
  });

  final PostImpl post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(padding: EdgeInsets.only(top: 18)),
        ListBody(
          children: [
            DimensionsName(
              l10n: l10n,
              width: post.width,
              height: post.height,
              name: post.id.toString(),
              icon: post.type.toIcon(),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
            PostInfoTile(post: post),
            const Padding(padding: EdgeInsets.only(top: 4)),
            const Divider(indent: 24, endIndent: 24),
            PostActionChips(post: post, addAppBarActions: true),
          ],
        ),
      ],
    );
  }
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
    final l10n = context.l10n();
    final tagManager = TagManager.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: TagsRibbon(
            tagNotifier: ImageTagsNotifier.of(context),
            emptyWidget: const Padding(padding: EdgeInsets.zero),
            sliver: false,
            selectTag: (str, controller) {
              HapticFeedback.mediumImpact();

              _launchGrid(context, str);
            },
            tagManager: TagManager.of(context),
            showPin: false,
            items: (tag, controller) => [
              PopupMenuItem(
                onTap: () {
                  if (tagManager.pinned.exists(tag)) {
                    tagManager.pinned.delete(tag);
                  } else {
                    tagManager.pinned.add(tag);
                  }

                  ImageViewInfoTilesRefreshNotifier.refreshOf(context);

                  controller.animateTo(
                    0,
                    duration: Durations.medium3,
                    curve: Easing.standard,
                  );
                },
                child: Text(
                  tagManager.pinned.exists(tag) ? l10n.unpinTag : l10n.pinTag,
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
            ],
          ),
        ),
        ListBody(
          children: [
            DimensionsName(
              l10n: l10n,
              width: post.width,
              height: post.height,
              name: post.id.toString(),
              icon: post.type.toIcon(),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
            PostInfoTile(post: post),
            const Padding(padding: EdgeInsets.only(top: 4)),
            const Divider(indent: 24, endIndent: 24),
            PostActionChips(post: post),
          ],
        ),
      ],
    );
  }
}

class PostActionChips extends StatelessWidget {
  const PostActionChips({
    super.key,
    required this.post,
    this.addAppBarActions = false,
  });

  final PostImpl post;

  final bool addAppBarActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final appBarActions = post.appBarButtons(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (addAppBarActions)
            ...appBarActions.map(
              (e) => ActionChip(
                onPressed: e.onPressed,
                avatar: Icon(e.icon),
                label: Text(e.label),
              ),
            ),
          ActionChip(
            onPressed: () => launchUrl(
              Uri.parse(post.fileDownloadUrl()),
              mode: LaunchMode.externalApplication,
            ),
            avatar: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.linkLabel),
          ),
          ActionChip(
            onPressed: post.sourceUrl.isNotEmpty &&
                    Uri.tryParse(post.sourceUrl) != null
                ? () => launchUrl(
                      Uri.parse(post.sourceUrl),
                      mode: LaunchMode.externalApplication,
                    )
                : null,
            label: Text(l10n.sourceFileInfoPage),
            avatar: const Icon(
              Icons.open_in_new_rounded,
              size: 18,
            ),
          ),
          if (post.tags.contains("translated"))
            TranslationNotesChip(
              postId: post.id,
              booru: post.booru,
            ),
        ],
      ),
    );
  }
}

class PostInfoTile extends StatelessWidget {
  const PostInfoTile({
    super.key,
    required this.post,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(15),
        bottomRight: Radius.circular(15),
      ),
    ),
  });

  final PostImpl post;

  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        shape: shape,
        tileColor: theme.colorScheme.surfaceContainerHigh,
        leading: const Icon(Icons.description_outlined),
        title: Text(post.booru.string),
        subtitle: Text.rich(
          TextSpan(
            text: post.rating.translatedName(l10n),
            children: [
              const TextSpan(text: " • "),
              WidgetSpan(
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, right: 4),
                  child: Icon(
                    Icons.thumb_up_alt_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ),
              TextSpan(text: "${post.score}"),
              TextSpan(text: "\n${l10n.date(post.createdAt)}"),
            ],
          ),
        ),
      ),
    );
  }
}

class DimensionsName extends StatelessWidget {
  const DimensionsName({
    super.key,
    required this.l10n,
    required this.width,
    required this.height,
    required this.name,
    required this.icon,
    this.trailing = const [],
    this.onTap,
    this.onLongTap,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
  });

  final int width;
  final int height;

  final String name;

  final List<Widget> trailing;

  final Icon icon;

  final ShapeBorder shape;

  final VoidCallback? onTap;
  final VoidCallback? onLongTap;

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongTap,
        shape: shape,
        tileColor: theme.colorScheme.surfaceContainerHigh,
        leading: icon,
        trailing: trailing.isEmpty
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: trailing,
              ),
        title: Text(name),
        subtitle: width == 0 && height == 0
            ? null
            : Text(
                "$width x ${l10n.pixels(height)}",
              ),
      ),
    );
  }
}

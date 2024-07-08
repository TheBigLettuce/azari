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
import "package:gallery/src/pages/booru/booru_restored_page.dart";
import "package:gallery/src/pages/gallery/files.dart";
import "package:gallery/src/pages/more/settings/radio_dialog.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";
import "package:gallery/src/widgets/translation_notes.dart";
import "package:qr_flutter/qr_flutter.dart";
import "package:url_launcher/url_launcher.dart";

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
        TagsRibbon(
          selectTag: (str) {
            HapticFeedback.mediumImpact();

            Navigator.pop(context);

            radioDialog<SafeMode>(
              context,
              SafeMode.values.map(
                (e) => (e, e.translatedString(l10n)),
              ),
              settings.safeMode,
              (s) {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return BooruRestoredPage(
                        booru: settings.selectedBooru,
                        tags: str,
                        saveSelectedPage: (e) {},
                        overrideSafeMode: s ?? settings.safeMode,
                        db: DatabaseConnectionNotifier.of(context),
                      );
                    },
                  ),
                );
              },
              title: l10n.chooseSafeMode,
              allowSingle: true,
            );
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
            // if (widget.addRemoveTag)
            //   PopupMenuItem(
            //     onTap: () {
            //       DatabaseConnectionNotifier.of(context)
            //           .localTags
            //           .removeSingle([widget.filename], tag);
            //     },
            //     child: Text(l10n.delete),
            //   ),
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
        ),
      ],
    );
  }
}

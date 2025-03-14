// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/obj_impls/post_impl.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/grid_cell/sticker.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
import "package:azari/src/widgets/translation_notes.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:url_launcher/url_launcher.dart" as url;

class PostInfo extends StatefulWidget {
  const PostInfo({
    super.key,
    required this.post,
    required this.tagManager,
    required this.settingsService,
  });

  final PostImpl post;
  final TagManagerService? tagManager;

  final SettingsService settingsService;

  @override
  State<PostInfo> createState() => _PostInfoState();
}

class _PostInfoState extends State<PostInfo> {
  TagManagerService? get tagManager => widget.tagManager;

  SettingsService get settingsService => widget.settingsService;

  late PostImpl post;

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

    // settings = widget.settingsService.current;
    post = widget.post;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tagManager != null)
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
              tagManager: tagManager,
              showPin: false,
              items: (tag, controller) => [
                PopupMenuItem(
                  onTap: () {
                    if (tagManager!.pinned.exists(tag)) {
                      tagManager!.pinned.delete(tag);
                    } else {
                      tagManager!.pinned.add(tag);
                    }

                    ImageViewInfoTilesRefreshNotifier.refreshOf(context);

                    controller.animateTo(
                      0,
                      duration: Durations.medium3,
                      curve: Easing.standard,
                    );
                  },
                  child: Text(
                    tagManager!.pinned.exists(tag)
                        ? l10n.unpinTag
                        : l10n.pinTag,
                  ),
                ),
                launchGridSafeModeItem(
                  context,
                  tag,
                  _launchGrid,
                  l10n,
                  settingsService: settingsService,
                ),
                PopupMenuItem(
                  onTap: () {
                    if (tagManager!.excluded.exists(tag)) {
                      tagManager!.excluded.delete(tag);
                    } else {
                      tagManager!.excluded.add(tag);
                    }
                  },
                  child: Text(
                    tagManager!.excluded.exists(tag)
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
          () => url.launchUrl(uri, mode: url.LaunchMode.externalApplication),
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
            ...appBarActions.where((e) => e.onPressed != null).map(
                  (e) => ActionChip(
                    onPressed: e.onPressed,
                    avatar: Icon(e.icon),
                    label: Text(e.label),
                  ),
                ),
          ActionChip(
            onPressed: () => url.launchUrl(
              Uri.parse(post.fileDownloadUrl()),
              mode: url.LaunchMode.externalApplication,
            ),
            avatar: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.linkLabel),
          ),
          ActionChip(
            onPressed: post.sourceUrl.isNotEmpty &&
                    Uri.tryParse(post.sourceUrl) != null
                ? () => url.launchUrl(
                      Uri.parse(post.sourceUrl),
                      mode: url.LaunchMode.externalApplication,
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
        // trailing: post is FavoritePost
        //     ? StarsButton(post: post as FavoritePost)
        //     : null,
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

class StarsButton extends StatefulWidget {
  const StarsButton({
    super.key,
    required this.idBooru,
    this.favoritePosts,
  });

  final (int id, Booru booru) idBooru;
  final FavoritePostSourceService? favoritePosts;

  @override
  State<StarsButton> createState() => _StarsButtonState();
}

class _StarsButtonState extends State<StarsButton> {
  (int id, Booru booru) get idBooru => widget.idBooru;
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;

  late final StreamSubscription<void>? favoriteEvents;

  FavoritePost? post;

  @override
  void initState() {
    super.initState();

    post = widget.favoritePosts?.cache.get(idBooru);

    favoriteEvents =
        favoritePosts?.cache.streamSingle(idBooru.$1, idBooru.$2).listen((e) {
      setState(() {
        post = widget.favoritePosts?.cache.get(idBooru);
      });
    });
  }

  @override
  void dispose() {
    favoriteEvents?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return const SizedBox.shrink();
    }

    return MenuAnchor(
      menuChildren: [
        Center(
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (post!.stars == FavoriteStars.one) {
                    post!.copyWith(stars: FavoriteStars.zeroFive).maybeSave();
                  } else if (post!.stars == FavoriteStars.zeroFive) {
                    post!.copyWith(stars: FavoriteStars.zero).maybeSave();
                  } else {
                    post!.copyWith(stars: FavoriteStars.one).maybeSave();
                  }
                },
                icon: post!.stars.includes(FavoriteStars.one)
                    ? const Icon(Icons.star_rounded, color: Colors.yellow)
                    : post!.stars.includes(FavoriteStars.zeroFive)
                        ? const Icon(
                            Icons.star_half_rounded,
                            color: Colors.yellow,
                          )
                        : const Icon(Icons.star_border_rounded),
              ),
              IconButton(
                onPressed: () {
                  if (post!.stars == FavoriteStars.two) {
                    post!.copyWith(stars: FavoriteStars.oneFive).maybeSave();
                  } else if (post!.stars == FavoriteStars.oneFive) {
                    post!.copyWith(stars: FavoriteStars.one).maybeSave();
                  } else {
                    post!.copyWith(stars: FavoriteStars.two).maybeSave();
                  }
                },
                icon: post!.stars.includes(FavoriteStars.two)
                    ? const Icon(Icons.star_rounded, color: Colors.yellow)
                    : post!.stars.includes(FavoriteStars.oneFive)
                        ? const Icon(
                            Icons.star_half_rounded,
                            color: Colors.yellow,
                          )
                        : const Icon(Icons.star_border_rounded),
              ),
              IconButton(
                onPressed: () {
                  if (post!.stars == FavoriteStars.three) {
                    post!.copyWith(stars: FavoriteStars.twoFive).maybeSave();
                  } else if (post!.stars == FavoriteStars.twoFive) {
                    post!.copyWith(stars: FavoriteStars.two).maybeSave();
                  } else {
                    post!.copyWith(stars: FavoriteStars.three).maybeSave();
                  }
                },
                icon: post!.stars.includes(FavoriteStars.three)
                    ? const Icon(Icons.star_rounded, color: Colors.yellow)
                    : post!.stars.includes(FavoriteStars.twoFive)
                        ? const Icon(
                            Icons.star_half_rounded,
                            color: Colors.yellow,
                          )
                        : const Icon(Icons.star_border_rounded),
              ),
              IconButton(
                onPressed: () {
                  if (post!.stars == FavoriteStars.four) {
                    post!.copyWith(stars: FavoriteStars.threeFive).maybeSave();
                  } else if (post!.stars == FavoriteStars.threeFive) {
                    post!.copyWith(stars: FavoriteStars.three).maybeSave();
                  } else {
                    post!.copyWith(stars: FavoriteStars.four).maybeSave();
                  }
                },
                icon: post!.stars.includes(FavoriteStars.four)
                    ? const Icon(Icons.star_rounded, color: Colors.yellow)
                    : post!.stars.includes(FavoriteStars.threeFive)
                        ? const Icon(
                            Icons.star_half_rounded,
                            color: Colors.yellow,
                          )
                        : const Icon(Icons.star_border_rounded),
              ),
              IconButton(
                onPressed: () {
                  if (post!.stars == FavoriteStars.five) {
                    post!.copyWith(stars: FavoriteStars.fourFive).maybeSave();
                  } else if (post!.stars == FavoriteStars.fourFive) {
                    post!.copyWith(stars: FavoriteStars.four).maybeSave();
                  } else {
                    post!.copyWith(stars: FavoriteStars.five).maybeSave();
                  }
                },
                icon: post!.stars.includes(FavoriteStars.five)
                    ? const Icon(Icons.star_rounded, color: Colors.yellow)
                    : post!.stars.includes(FavoriteStars.fourFive)
                        ? const Icon(
                            Icons.star_half_rounded,
                            color: Colors.yellow,
                          )
                        : const Icon(Icons.star_border_rounded),
              ),
            ],
          ),
        ),
      ],
      consumeOutsideTap: true,
      alignmentOffset: const Offset(0, 40),
      style: const MenuStyle(
        alignment: Alignment.topLeft,
        visualDensity: VisualDensity.compact,
      ),
      builder: (context, controller, _) => IconButton(
        onLongPress: () {
          post!.copyWith(stars: FavoriteStars.zero).maybeSave();
        },
        onPressed: controller.open,
        icon: Badge(
          label: Text(
            switch (post!.stars) {
              FavoriteStars.zero => 0,
              FavoriteStars.zeroFive => 0.5,
              FavoriteStars.one => 1,
              FavoriteStars.oneFive => 1.5,
              FavoriteStars.two => 2,
              FavoriteStars.twoFive => 2.5,
              FavoriteStars.three => 3,
              FavoriteStars.threeFive => 3.5,
              FavoriteStars.four => 4,
              FavoriteStars.fourFive => 4.5,
              FavoriteStars.five => 5,
            }
                .toString(),
          ),
          isLabelVisible: post!.stars != FavoriteStars.zero,
          child: switch (post!.stars) {
            FavoriteStars.zero ||
            FavoriteStars.zeroFive ||
            FavoriteStars.one ||
            FavoriteStars.oneFive ||
            FavoriteStars.two =>
              const Icon(Icons.star_outline_rounded),
            FavoriteStars.twoFive ||
            FavoriteStars.three ||
            FavoriteStars.threeFive ||
            FavoriteStars.four ||
            FavoriteStars.fourFive =>
              Icon(
                Icons.star_half_rounded,
                color: Colors.yellow.shade500,
              ),
            FavoriteStars.five => const Icon(
                Icons.star_rounded,
                color: Colors.yellowAccent,
              ),
          },
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

class VideoGifRow extends StatelessWidget {
  const VideoGifRow({
    super.key,
    required this.isVideo,
    required this.isGif,
  });

  final bool isVideo;
  final bool isGif;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 2,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isGif)
          const _VideoGifIcon(
            icon: Icons.gif_rounded,
          ),
        if (isVideo)
          const _VideoGifIcon(
            icon: Icons.play_arrow_rounded,
          ),
        // if (score > 10) _Score(score: score),
      ],
    );
  }
}

class PostTagsWrap extends StatefulWidget {
  const PostTagsWrap({
    super.key,
    required this.post,
    required this.letterCount,
    required this.verySmall,
  });

  final bool verySmall;

  final int letterCount;

  final PostImpl post;

  @override
  State<PostTagsWrap> createState() => _PostTagsWrapState();
}

class _PostTagsWrapState extends State<PostTagsWrap> {
  List<String> pinnedTags = [];
  bool hasVideo = false;
  bool hasGif = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final tags = PinnedTagsProvider.of(context);
    pinnedTags = widget.post.tags.where((e) {
      if (hasGif || e == "gif") {
        hasGif = true;
      }

      if (hasVideo || e == "video") {
        hasVideo = true;
      }

      return tags.$1.containsKey(e);
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.verySmall ? 42 / 2 : 42,
      child: Wrap(
        clipBehavior: Clip.antiAlias,
        verticalDirection: VerticalDirection.up,
        runSpacing: 2,
        spacing: 2,
        children: [
          if (hasGif)
            const _VideoGifIcon(
              icon: Icons.gif_box_rounded,
            ),
          if (hasVideo)
            const _VideoGifIcon(
              icon: Icons.play_arrow_rounded,
            ),
          ...pinnedTags.map(
            (e) => PinnedTagChip(
              tag: e,
              tight: true,
              letterCount: widget.letterCount,
              mildlyTransculent: true,
            ),
          ),
        ],
      ),
    );
  }
}

// class _Score extends StatelessWidget {
//   const _Score({
//     // super.key,
//     required this.score,
//   });

//   final int score;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return DecoratedBox(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         color: score > 80
//             ? colorScheme.onPrimary.withValues(alpha: 0.2)
//             : colorScheme.surfaceContainerLow.withValues(alpha: 0.1),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               score > 80 ? Icons.whatshot_rounded : Icons.thumb_up_rounded,
//               size: 12,
//               color: score > 80
//                   ? colorScheme.primary.withValues(alpha: 0.9)
//                   : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
//             ),
//             const Padding(padding: EdgeInsets.only(right: 4)),
//             Text(
//               score.toString(),
//               style: theme.textTheme.labelMedium?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _VideoGifIcon extends StatelessWidget {
  const _VideoGifIcon({
    // super.key,
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.secondary.withValues(alpha: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSecondary.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class FavoritePostButton extends StatefulWidget {
  const FavoritePostButton({
    super.key,
    required this.post,
    required this.favoritePosts,
    this.withBackground = true,
  });

  final PostImpl post;
  final FavoritePostSourceService favoritePosts;
  final bool withBackground;

  @override
  State<FavoritePostButton> createState() => _FavoritePostButtonState();
}

class _FavoritePostButtonState extends State<FavoritePostButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final StreamSubscription<void> events;

  bool favorite = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);

    favorite = widget.favoritePosts.cache
        .isFavorite(widget.post.id, widget.post.booru);

    events = widget.favoritePosts.cache
        .streamSingle(widget.post.id, widget.post.booru)
        .listen((newFavorite) {
      if (newFavorite == favorite) {
        return;
      }

      favorite = newFavorite;

      if (favorite) {
        controller.forward().then((_) => controller.reverse());
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder(
      curve: Easing.linear,
      tween: ColorTween(
        end: favorite ? Colors.pink : theme.colorScheme.surfaceContainer,
      ),
      duration: Durations.short3,
      builder: (context, value, child) => IconButton(
        style: widget.withBackground
            ? ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  value,
                ),
                backgroundColor: WidgetStatePropertyAll(
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                ),
              )
            : null,
        onPressed: () {
          widget.favoritePosts.addRemove([widget.post]);
        },
        icon: Animate(
          controller: controller,
          value: 0,
          autoPlay: false,
          effects: const [
            ScaleEffect(
              delay: Duration(milliseconds: 40),
              duration: Durations.short3,
              begin: Offset(1, 1),
              end: Offset(2, 2),
              curve: Easing.emphasizedDecelerate,
            ),
          ],
          child: Icon(
            favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          ),
        ),
      ),
    );
  }
}

class LinearDownloadIndicator extends StatefulWidget {
  const LinearDownloadIndicator({
    super.key,
    required this.downloadManager,
    required this.post,
  });

  final DownloadManager downloadManager;
  final PostImpl post;

  @override
  State<LinearDownloadIndicator> createState() =>
      _LinearDownloadIndicatorState();
}

class _LinearDownloadIndicatorState extends State<LinearDownloadIndicator> {
  late final StreamSubscription<void> events;
  DownloadHandle? status;

  @override
  void initState() {
    events = widget.downloadManager.watch(
      (_) {
        setState(() {
          status =
              widget.downloadManager.statusFor(widget.post.fileDownloadUrl());
        });
      },
      true,
    );

    super.initState();
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final downloadStatus = status?.data.status;

    return status == null || status!.data.status == DownloadStatus.failed
        ? const SizedBox.shrink()
        : _LinearProgress(handle: status!);
  }
}

class DownloadButton extends StatefulWidget {
  const DownloadButton({
    super.key,
    required this.post,
    required this.downloadManager,
    required this.localTags,
    required this.settingsService,
  });

  final PostImpl post;

  final DownloadManager downloadManager;
  final LocalTagsService localTags;
  final SettingsService settingsService;

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  DownloadManager get downloadManager => widget.downloadManager;
  LocalTagsService get localTags => widget.localTags;
  SettingsService get settingsService => widget.settingsService;

  late final StreamSubscription<void> events;
  DownloadHandle? status;

  @override
  void initState() {
    super.initState();

    events = widget.downloadManager.watch(
      (_) {
        setState(() {
          status =
              widget.downloadManager.statusFor(widget.post.fileDownloadUrl());
        });
      },
      true,
    );
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadStatus = status?.data.status;

    final icon = switch (downloadStatus) {
      null => const Icon(Icons.download_rounded),
      DownloadStatus.onHold => const Icon(Icons.download_rounded),
      DownloadStatus.failed => const Icon(Icons.file_download_off_rounded),
      DownloadStatus.inProgress => const Icon(Icons.downloading_rounded),
    };

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: downloadStatus == DownloadStatus.onHold ||
                  downloadStatus == DownloadStatus.inProgress
              ? null
              : () {
                  if (downloadStatus == DownloadStatus.failed) {
                    widget.downloadManager.restartAll([status!]);
                  } else {
                    widget.post.download(
                      downloadManager: widget.downloadManager,
                      localTags: localTags,
                      settingsService: settingsService,
                    );
                    WrapperSelectionAnimation.tryPlayOf(context);
                  }
                },
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              downloadStatus == DownloadStatus.inProgress ||
                      downloadStatus == DownloadStatus.onHold
                  ? const CircleBorder()
                  : const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
            ),
            foregroundColor: WidgetStateProperty.fromMap(
              {
                WidgetState.disabled: theme.disabledColor,
                WidgetState.any:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              },
            ),
            backgroundColor: WidgetStateProperty.fromMap({
              WidgetState.disabled:
                  theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
              WidgetState.any:
                  theme.colorScheme.surfaceContainer.withValues(alpha: 0.8),
            }),
          ),
          icon: icon,
        ),
        if (status != null && downloadStatus == DownloadStatus.inProgress)
          _Progress(handle: status!),
      ],
    );
  }
}

class _LinearProgress extends StatefulWidget {
  const _LinearProgress({
    // super.key,
    required this.handle,
  });

  final DownloadHandle handle;

  @override
  State<_LinearProgress> createState() => __LinearProgressState();
}

class __LinearProgressState extends State<_LinearProgress> {
  late final StreamSubscription<void> subscription;

  double? progress;

  @override
  void initState() {
    super.initState();

    subscription = widget.handle.watchProgress((i) {
      setState(() {
        progress = i;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      autoPlay: true,
      effects: const [
        FadeEffect(
          duration: Durations.medium4,
          curve: Easing.standard,
          begin: 0,
          end: 1,
        ),
      ],
      child: LinearProgressIndicator(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        minHeight: 2,
        year2023: false,
        value: progress,
      ),
    );
  }
}

class _Progress extends StatefulWidget {
  const _Progress({
    // super.key,
    required this.handle,
  });

  final DownloadHandle handle;

  @override
  State<_Progress> createState() => __ProgressState();
}

class __ProgressState extends State<_Progress> {
  late final StreamSubscription<void> subscription;

  double? progress;

  @override
  void initState() {
    super.initState();

    subscription = widget.handle.watchProgress((i) {
      setState(() {
        progress = i;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 38,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        value: progress,
      ),
    );
  }
}

mixin PinnedSortedTagsArrayMixin<S extends StatefulWidget> on State<S> {
  List<String> get postTags;

  List<({String tag, bool pinned})> _tags = [];
  List<({String tag, bool pinned})> get tags => _tags;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (postTags.isEmpty) {
      return;
    }

    final tags = PinnedTagsProvider.of(context);
    final postTags_ = postTags.toList();
    final pinnedTags = <String>[];
    postTags_.removeWhere((e) {
      if (tags.$1.containsKey(e)) {
        pinnedTags.add(e);

        return true;
      }

      return false;
    });

    _tags = pinnedTags
        .map((e) => (tag: e, pinned: true))
        .followedBy(postTags_.map((e) => (tag: e, pinned: false)))
        // .take(10)
        .toList();

    setState(() {});
  }
}

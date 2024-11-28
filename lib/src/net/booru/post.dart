// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/post_tags.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/post_functions.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/home/home.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/sticker_widget.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:azari/src/widgets/image_view/wrappers/wrap_image_view_skeleton.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:mime/mime.dart" as mime;
import "package:path/path.dart" as path_util;
import "package:transparent_image/transparent_image.dart";
import "package:url_launcher/url_launcher.dart";

final _transparent = MemoryImage(kTransparentImage);

abstract class PostImpl
    implements
        PostBase,
        // SelectionWrapperBuilder,
        ContentableCell,
        Thumbnailable,
        ContentWidgets,
        AppBarButtonable,
        ImageViewActionable,
        Infoable,
        Stickerable,
        Downloadable {
  const PostImpl();

  String _makeName() =>
      ParsedFilenameResult.makeFilename(booru, fileDownloadUrl(), md5, id);

  @override
  CellStaticData description() => const CellStaticData();

  @override
  Widget info(BuildContext context) => PostInfo(post: this);

  @override
  Widget buildCell<T extends CellBase>(
    BuildContext context,
    int idx,
    T cell, {
    required bool isList,
    required bool hideTitle,
    bool animated = false,
    bool blur = false,
    required Alignment imageAlign,
    required Widget Function(Widget child) wrapSelection,
  }) =>
      this is FavoritePost
          ? _FavoriteCellWidget(
              key: uniqueKey(),
              wrapSelection: wrapSelection,
              post: this as FavoritePost,
            )
          : wrapSelection(_CellWidget(post: this));

  @override
  List<NavigationAction> appBarButtons(BuildContext context) {
    return [
      NavigationAction(
        Icons.public,
        () {
          launchUrl(
            booru.browserLink(id),
            mode: LaunchMode.externalApplication,
          );
        },
      ),
      NavigationAction(
        Icons.share,
        () {
          PlatformApi().shareMedia(fileUrl, url: true);
        },
      ),
    ];
  }

  @override
  List<ImageViewAction> actions(BuildContext context) {
    final theme = Theme.of(context);

    final db = DatabaseConnectionNotifier.of(context);
    final favorites = db.favoritePosts;
    final hidden = db.hiddenBooruPost;

    return [
      ImageViewAction(
        Icons.favorite_border_rounded,
        (_) => favorites.addRemove([this]),
        animate: true,
        watch: (f, [fire = false]) => db.favoritePosts.watchSingle(
          id,
          booru,
          (isFavorite_) => (
            isFavorite_
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            isFavorite_
                ? Colors.red.harmonizeWith(theme.colorScheme.primary)
                : null,
            !isFavorite_,
          ),
          f,
          fire,
        ),
      ),
      ImageViewAction(
        Icons.download,
        (_) => download(
          DownloadManager.of(context),
          PostTags.fromContext(context),
        ),
        animate: true,
        animation: const [
          SlideEffect(
            curve: Easing.emphasizedAccelerate,
            duration: Durations.medium1,
            begin: Offset.zero,
            end: Offset(0, -0.4),
          ),
          FadeEffect(
            delay: Duration(milliseconds: 60),
            curve: Easing.standard,
            duration: Durations.medium1,
            begin: 1,
            end: 0,
          ),
        ],
      ),
      if (this is! FavoritePost)
        ImageViewAction(
          Icons.hide_image_rounded,
          (_) {
            if (hidden.isHidden(id, booru)) {
              hidden.removeAll([(id, booru)]);
            } else {
              hidden.addAll([
                HiddenBooruPostData(
                  thumbUrl: previewUrl,
                  postId: id,
                  booru: booru,
                ),
              ]);
            }
          },
          watch: (f, [fire = false]) {
            return hidden
                .streamSingle(id, booru, fire)
                .map<(IconData?, Color?, bool?)>((e) {
              return (
                null,
                e
                    ? Colors.lightBlue.harmonizeWith(theme.colorScheme.primary)
                    : null,
                null
              );
            }).listen(f);
          },
        ),
    ];
  }

  @override
  ImageProvider<Object> thumbnail() {
    if (HiddenBooruPostService.db().isHidden(id, booru)) {
      return _transparent;
    }

    return CachedNetworkImageProvider(previewUrl);
  }

  @override
  Contentable content() {
    final url = Post.getUrl(this);

    return switch (type) {
      PostContentType.none => EmptyContent(this),
      PostContentType.video => NetVideo(
          this,
          path_util.extension(url) == ".zip" ? sampleUrl : url,
        ),
      PostContentType.gif => NetGif(this, NetworkImage(url)),
      PostContentType.image => NetImage(this, NetworkImage(url)),
    };
  }

  @override
  Key uniqueKey() => ValueKey(fileUrl);

  @override
  String alias(bool isList) => isList ? _makeName() : id.toString();

  @override
  String fileDownloadUrl() {
    if (path_util.extension(fileUrl) == ".zip") {
      return sampleUrl;
    } else {
      return fileUrl;
    }
  }

  @override
  List<Sticker> stickers(BuildContext context, bool excludeDuplicate) {
    if (this is FavoritePost) {
      return [
        if (type == PostContentType.video)
          Sticker(
            FilteringMode.video.icon,
            subtitle: "",
          ),
        if (type == PostContentType.gif)
          Sticker(
            FilteringMode.gif.icon,
            subtitle: "",
          ),
        if (excludeDuplicate && tags.contains("original"))
          Sticker(FilteringMode.original.icon),
        if (excludeDuplicate && tags.contains("translated"))
          const Sticker(Icons.translate_outlined),
      ];
    }

    if (excludeDuplicate) {
      final icons = [
        if (score > 10)
          Sticker(
            score > 80 ? Icons.whatshot_rounded : Icons.thumb_up_rounded,
            subtitle: score.toString(),
            important: score > 80,
          ),
        ...defaultStickersPost(
          type,
          context,
          tags,
          id,
          booru,
        ),
      ];

      return icons.isEmpty ? const [] : icons;
    }

    final db = DatabaseConnectionNotifier.of(context);

    final isHidden = db.hiddenBooruPost.isHidden(id, booru);

    return [
      if (isHidden) const Sticker(Icons.hide_image_rounded),
      ...defaultStickersPost(
        type,
        context,
        tags,
        id,
        booru,
      ),
    ];
  }
}

enum PostRating {
  general,
  sensitive,
  questionable,
  explicit;

  String translatedName(AppLocalizations l10n) => switch (this) {
        PostRating.general => l10n.enumPostRatingGeneral,
        PostRating.sensitive => l10n.enumPostRatingSensitive,
        PostRating.questionable => l10n.enumPostRatingQuestionable,
        PostRating.explicit => l10n.enumPostRatingExplicit,
      };

  SafeMode get asSafeMode => switch (this) {
        PostRating.general => SafeMode.normal,
        PostRating.sensitive => SafeMode.relaxed,
        PostRating.questionable || PostRating.explicit => SafeMode.none,
      };
}

enum PostContentType {
  none,
  video,
  gif,
  image;

  static PostContentType fromUrl(String url) {
    final t = mime.lookupMimeType(url);
    if (t == null) {
      return PostContentType.none;
    }

    final typeHalf = t.split("/");

    if (typeHalf[0] == "image") {
      return typeHalf[1] == "gif" ? PostContentType.gif : PostContentType.image;
    } else if (typeHalf[0] == "video") {
      return PostContentType.video;
    } else {
      throw "";
    }
  }
}

abstract class PostBase {
  const PostBase();

  int get id;

  String get md5;

  List<String> get tags;

  int get width;
  int get height;

  String get fileUrl;
  String get previewUrl;
  String get sampleUrl;
  String get sourceUrl;
  PostRating get rating;
  int get score;
  DateTime get createdAt;
  Booru get booru;
  PostContentType get type;
}

mixin DefaultPostPressable<T extends PostImpl> implements Pressable<T> {
  @override
  void onPress(
    BuildContext context,
    GridFunctionality<T> functionality,
    int idx,
  ) {
    final db = DatabaseConnectionNotifier.of(context);
    final tagManager = TagManager.of(context);

    ImageView.defaultForGrid<T>(
        context,
        functionality,
        ImageViewDescription(
          ignoreOnNearEnd: false,
          statistics: StatisticsBooruService.asImageViewStatistics(),
        ),
        idx,
        (c) => imageViewTags(c, tagManager),
        (c, f) => watchTags(c, f, tagManager), (post) {
      db.visitedPosts.addAll([
        VisitedPost(
          booru: post.booru,
          id: post.id,
          rating: post.rating,
          thumbUrl: post.previewUrl,
          date: DateTime.now(),
        ),
      ]);
    });
  }

  static List<ImageTag> imageViewTags(Contentable c, TagManager tagManager) =>
      (c.widgets as PostBase)
          .tags
          .map(
            (e) => ImageTag(
              e,
              favorite: tagManager.pinned.exists(e),
              excluded: tagManager.excluded.exists(e),
            ),
          )
          .toList();

  static StreamSubscription<List<ImageTag>> watchTags(
    Contentable c,
    void Function(List<ImageTag> l) f,
    TagManager tagManager,
  ) =>
      tagManager.pinned.watchImage((c.widgets as PostBase).tags, f);
}

extension MultiplePostDownloadExt on List<PostImpl> {
  void downloadAll(
    DownloadManager downloadManager,
    PostTags postTags, [
    PathVolume? thenMoveTo,
  ]) {
    downloadManager.addLocalTags(
      map(
        (e) => DownloadEntryTags.d(
          tags: e.tags,
          name: ParsedFilenameResult.makeFilename(
            e.booru,
            e.fileDownloadUrl(),
            e.md5,
            e.id,
          ),
          url: e.fileDownloadUrl(),
          thumbUrl: e.previewUrl,
          site: e.booru.url,
          thenMoveTo: thenMoveTo,
        ),
      ),
      SettingsService.db().current,
      postTags,
    );
  }
}

extension PostDownloadExt on PostImpl {
  void download(
    DownloadManager downloadManager,
    PostTags postTags, [
    PathVolume? thenMoveTo,
  ]) {
    downloadManager.addLocalTags(
      [
        DownloadEntryTags.d(
          tags: tags,
          name: ParsedFilenameResult.makeFilename(
            booru,
            fileDownloadUrl(),
            md5,
            id,
          ),
          url: fileDownloadUrl(),
          thumbUrl: previewUrl,
          site: booru.url,
          thenMoveTo: thenMoveTo,
        ),
      ],
      SettingsService.db().current,
      postTags,
    );
  }
}

class _CellWidget extends StatelessWidget {
  const _CellWidget({
    // super.key,
    required this.post,
  });

  final PostImpl post;

  int calculateTagsChipLetterCount(Size biggest) {
    return switch (biggest) {
      Size(height: > 190, width: > 190) => 10,
      Size(height: > 180, width: > 180) => 8,
      Size(height: > 90, width: > 90) => 7,
      Size() => 10,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = post.thumbnail();
    final downloader = DownloadManager.of(context);

    final animate = PlayAnimations.maybeOf(context) ?? false;

    final child = Card(
      elevation: 0,
      color: theme.cardColor.withValues(alpha: 0),
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                GridCellImage(
                  imageAlign: Alignment.topCenter,
                  thumbnail: thumbnail,
                  blur: false,
                ),
                if (constraints.maxHeight > 80 &&
                    constraints.maxWidth > 80) ...[
                  // if (post is! FavoritePost)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FavoriteButton(
                            post: post,
                            favoritePosts:
                                DatabaseConnectionNotifier.of(context)
                                    .favoritePosts,
                          ),
                          if (post.score > 10)
                            StickerWidget(
                              Sticker(
                                post.score > 80
                                    ? Icons.whatshot_rounded
                                    : Icons.thumb_up_rounded,
                                subtitle: post.score.toString(),
                                important: post.score > 80,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: post is FavoritePost
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 6,
                                bottom: 6,
                                left: 6,
                              ),
                              child: _TagsWrap(
                                post: post,
                                verySmall: constraints.maxWidth < 100,
                                letterCount: calculateTagsChipLetterCount(
                                  constraints.biggest,
                                ),
                              ),
                            ),
                          ),
                          _DownloadIcon(
                            downloadManager: downloader,
                            post: post,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );

    return animate ? child.animate(key: post.uniqueKey()).fadeIn() : child;
  }
}

class _FavoriteCellWidget extends StatefulWidget {
  const _FavoriteCellWidget({
    super.key,
    required this.post,
    required this.wrapSelection,
  });

  final FavoritePost post;

  final Widget Function(Widget child) wrapSelection;

  @override
  State<_FavoriteCellWidget> createState() => __FavoriteCellWidgetState();
}

class __FavoriteCellWidgetState extends State<_FavoriteCellWidget> {
  FavoritePost get post => widget.post;

  List<({String tag, bool pinned})> _tags = [];
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
    final postTags = widget.post.tags.toList();
    final pinnedTags = <String>[];
    postTags.removeWhere((e) {
      if (hasGif || e == "gif") {
        hasGif = true;
      }

      if (hasVideo || e == "video") {
        hasVideo = true;
      }

      if (tags.$1.containsKey(e)) {
        pinnedTags.add(e);

        return true;
      }

      return false;
    });

    _tags = pinnedTags
        .map((e) => (tag: e, pinned: true))
        .followedBy(postTags.map((e) => (tag: e, pinned: false)))
        .toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = post.thumbnail();

    final animate = PlayAnimations.maybeOf(context) ?? false;

    final child = LayoutBuilder(
      builder: (context, constraints) {
        final verySmall =
            constraints.maxWidth < 100 || constraints.maxHeight < 100;

        final card = widget.wrapSelection(
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            color: theme.cardColor.withValues(alpha: 0),
            child: Stack(
              children: [
                GridCellImage(
                  imageAlign: Alignment.topCenter,
                  thumbnail: thumbnail,
                  blur: false,
                ),
                if (hasGif)
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: _VideoGifIcon(
                        icon: Icons.gif_rounded,
                      ),
                    ),
                  ),
                if (hasVideo)
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: _VideoGifIcon(
                        icon: Icons.play_arrow_rounded,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        if (_tags.isEmpty) {
          return card;
        }

        return Column(
          children: [
            Expanded(child: card),
            SizedBox(
              height: verySmall ? 42 / 2 : 42 / 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Wrap(
                  clipBehavior: Clip.antiAlias,
                  runSpacing: 2,
                  spacing: 2,
                  children: [
                    ..._tags.take(10).map(
                          (e) => OutlinedTagChip(
                            tag: e.tag,
                            letterCount: 8,
                            isPinned: e.pinned,
                            onPressed: () => OnBooruTagPressed.pressOf(
                              context,
                              e.tag,
                              widget.post.booru,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    return animate ? child.animate(key: post.uniqueKey()).fadeIn() : child;
  }
}

class _TagsWrap extends StatefulWidget {
  const _TagsWrap({
    super.key,
    required this.post,
    required this.letterCount,
    required this.verySmall,
  });

  final bool verySmall;

  final int letterCount;

  final PostImpl post;

  @override
  State<_TagsWrap> createState() => __TagsWrapState();
}

class __TagsWrapState extends State<_TagsWrap> {
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

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({
    // super.key,
    required this.post,
    required this.favoritePosts,
  });

  final PostImpl post;
  final FavoritePostSourceService favoritePosts;

  @override
  State<_FavoriteButton> createState() => __FavoriteButtonState();
}

class __FavoriteButtonState extends State<_FavoriteButton> {
  late final StreamSubscription<void> events;

  bool favorite = false;

  @override
  void initState() {
    super.initState();

    favorite =
        widget.favoritePosts.isFavorite(widget.post.id, widget.post.booru);

    events = widget.favoritePosts
        .streamSingle(widget.post.id, widget.post.booru)
        .listen((newFavorite) {
      setState(() {
        favorite = newFavorite;
      });
    });
  }

  @override
  void dispose() {
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
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(
            value,
          ),
          backgroundColor: WidgetStatePropertyAll(
            theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
        ),
        onPressed: () {
          widget.favoritePosts.addRemove([widget.post]);
        },
        icon: Icon(
          favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        ),
      ),
    );
  }
}

class _DownloadIcon extends StatefulWidget {
  const _DownloadIcon({
    // super.key,
    required this.downloadManager,
    required this.post,
  });

  final DownloadManager downloadManager;
  final PostImpl post;

  @override
  State<_DownloadIcon> createState() => __DownloadIconState();
}

class __DownloadIconState extends State<_DownloadIcon> {
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
                    widget.downloadManager
                        .restartAll([status!], SettingsService.db().current);
                  } else {
                    widget.post.download(
                      widget.downloadManager,
                      PostTags.fromContext(context),
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
          _Progress(
            handle: status!,
          ),
      ],
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

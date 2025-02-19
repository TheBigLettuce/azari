// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/obj_impls/post_impl.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/other/settings/radio_dialog.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/sticker_widget.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/widgets/image_view/video/photo_gallery_page_video.dart";
import "package:azari/src/widgets/post_info.dart";
import "package:azari/src/widgets/post_info_simple.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photo_view/photo_view.dart";

class PostCell extends StatefulWidget {
  const PostCell({
    super.key,
    required this.post,
    required this.wrapSelection,
    required this.favoritePosts,
    required this.tagManager,
    required this.downloadManager,
    required this.settingsService,
  });

  final PostImpl post;

  final FavoritePostSourceService? favoritePosts;
  final TagManagerService? tagManager;
  final DownloadManager? downloadManager;

  final SettingsService settingsService;

  final Widget Function(Widget child) wrapSelection;

  static void openMaximizedImage(
    BuildContext context,
    PostImpl post,
    Contentable content,
  ) {
    Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        fullscreenDialog: true,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          final videoSettings = Services.getOf<VideoSettingsService>(context);

          return _ExpandedImage(
            post: post,
            content: content,
            videoSettings: videoSettings,
          );
        },
      ),
    );
  }

  @override
  State<PostCell> createState() => _CellWidgetState();
}

class _CellWidgetState extends State<PostCell>
    with PinnedSortedTagsArrayMixin, SettingsWatcherMixin {
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;
  TagManagerService? get tagManager => widget.tagManager;
  DownloadManager? get downloadManager => widget.downloadManager;

  @override
  SettingsService get settingsService => widget.settingsService;

  PostImpl get post => widget.post;
  @override
  List<String> get postTags => widget.post.tags;

  final controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = post.thumbnail(context);

    final animate = PlayAnimations.maybeOf(context) ?? false;

    final content = post.content(context);
    final stickers = post.stickers(context, false);

    final child = Builder(
      builder: (context) {
        final card = widget.wrapSelection(
          Builder(
            builder: (context) => GestureDetector(
              child: Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                color: theme.cardColor.withValues(alpha: 0),
                child: Stack(
                  children: [
                    GridCellImage(
                      heroTag: post.uniqueKey(),
                      imageAlign: Alignment.topCenter,
                      thumbnail: post.type == PostContentType.gif &&
                              post.size != 0 &&
                              !post.size.isNegative &&
                              post.size < 524288
                          ? CachedNetworkImageProvider(
                              post.sampleUrl.isEmpty
                                  ? post.fileUrl
                                  : post.sampleUrl,
                            )
                          : thumbnail,
                      blur: false,
                    ),
                    if (favoritePosts != null && widget.post is! FavoritePost)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: FavoritePostButton(
                          post: post,
                          favoritePosts: favoritePosts!,
                        ),
                      ),
                    if (stickers.isNotEmpty)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            direction: Axis.vertical,
                            children: stickers.map(StickerWidget.new).toList(),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: VideoGifRow(
                          isVideo: widget.post.type == PostContentType.video,
                          isGif: widget.post.type == PostContentType.gif,
                        ),
                      ),
                    ),
                    if (downloadManager != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: LinearDownloadIndicator(
                          downloadManager: downloadManager!,
                          post: post,
                        ),
                      ),
                    if (post is! FavoritePost &&
                        post.type == PostContentType.image)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: IconButton(
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: WidgetStatePropertyAll(
                                theme.colorScheme.surface
                                    .withValues(alpha: 0.9),
                              ),
                              backgroundColor: WidgetStatePropertyAll(
                                theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            onPressed: () => PostCell.openMaximizedImage(
                              context,
                              post,
                              settings.sampleThumbnails
                                  ? content
                                  : post.content(context, true),
                            ),
                            icon: const Icon(Icons.open_in_full),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (tags.isEmpty) {
          return card;
        }

        return Column(
          children: [
            Expanded(child: card),
            SizedBox(
              height: 21,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.antiAlias,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final e = tags[index];

                    return OutlinedTagChip(
                      tag: e.tag,
                      letterCount: 8,
                      isPinned: e.pinned,
                      onDoublePressed: e.pinned || tagManager == null
                          ? null
                          : () {
                              controller.animateTo(
                                0,
                                duration: Durations.medium3,
                                curve: Easing.standard,
                              );

                              tagManager!.pinned.add(e.tag);
                            },
                      onLongPressed: widget.post is FavoritePost
                          ? null
                          : () {
                              context.openSafeModeDialog(settingsService,
                                  (safeMode) {
                                OnBooruTagPressed.pressOf(
                                  context,
                                  e.tag,
                                  widget.post.booru,
                                  overrideSafeMode: safeMode,
                                );
                              });
                            },
                      onPressed: () => OnBooruTagPressed.pressOf(
                        context,
                        e.tag,
                        widget.post.booru,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    if (animate) {
      return child.animate(key: post.uniqueKey()).fadeIn();
    }

    return child;
  }
}

class _ExpandedImage extends StatelessWidget {
  const _ExpandedImage({
    // super.key,
    required this.post,
    required this.content,
    required this.videoSettings,
  });

  final PostImpl post;
  final Contentable content;

  final VideoSettingsService? videoSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
      iconColor: WidgetStatePropertyAll(theme.colorScheme.onSurface),
    );

    final child = content is NetVideo
        ? _ExpandedVideo(
            post: post,
            videoSettings: videoSettings,
            child: PhotoGalleryPageVideo(
              url: (content as NetVideo).uri,
              networkThumb: post.thumbnail(context),
              localVideo: false,
              videoSettings: videoSettings,
            ),
          )
        : PhotoView(
            heroAttributes: PhotoViewHeroAttributes(tag: post.uniqueKey()),
            maxScale: PhotoViewComputedScale.contained * 1.8,
            minScale: PhotoViewComputedScale.contained * 0.8,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, event) => const ShimmerLoadingIndicator(),
            backgroundDecoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0),
            ),
            imageProvider: content is NetImage
                ? (content as NetImage).provider
                : (content as NetGif).provider,
          );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: buttonStyle,
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
                    ),
                    child: SizedBox(
                      width: MediaQuery.sizeOf(sheetContext).width,
                      child: PostInfoSimple(post: post),
                    ),
                  );
                },
              );
            },
            style: buttonStyle,
            icon: const Icon(Icons.info_outline),
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      body: GestureDeadZones(
        left: true,
        right: true,
        child: child,
      ),
    );
  }
}

class _ExpandedVideo extends StatefulWidget {
  const _ExpandedVideo({
    // super.key,
    required this.post,
    required this.videoSettings,
    required this.child,
  });

  final PostImpl post;
  final VideoSettingsService? videoSettings;

  final Widget child;

  @override
  State<_ExpandedVideo> createState() => __ExpandedVideoState();
}

class __ExpandedVideoState extends State<_ExpandedVideo> {
  final videoControls = VideoControlsControllerImpl();
  final pauseVideoState = PauseVideoState();

  final seekTimeAnchor = GlobalKey<SeekTimeAnchorState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    videoControls.dispose();
    pauseVideoState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Center(
      child: VideoControlsNotifier(
        controller: videoControls,
        child: PauseVideoNotifierHolder(
          state: pauseVideoState,
          child: Stack(
            alignment: Alignment.center,
            children: [
              widget.child,
              SeekTimeAnchor(
                key: seekTimeAnchor,
                bottomPadding: viewPadding.bottom + 20,
                videoControls: videoControls,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: viewPadding.bottom + 20),
                  child: VideoControls(
                    videoControls: videoControls,
                    videoSettings: widget.videoSettings,
                    seekTimeAnchor: seekTimeAnchor,
                    vertical: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

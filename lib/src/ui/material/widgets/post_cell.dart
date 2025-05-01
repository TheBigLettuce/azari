// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:ui";

import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/other/settings/radio_dialog.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/ui/material/widgets/image_view/video/photo_gallery_page_video.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:azari/src/ui/material/widgets/post_info_simple.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_loading_indicator.dart";
import "package:azari/src/ui/material/widgets/wrap_future_restartable.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:go_router/go_router.dart";
import "package:photo_view/photo_view.dart";

class PostCell extends StatefulWidget {
  const PostCell({
    required super.key,
    required this.post,
  });

  final PostImpl post;

  @override
  State<PostCell> createState() => _PostCellState();
}

class _PostCellState extends State<PostCell>
    with PinnedSortedTagsArrayMixin, SettingsWatcherMixin {
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
    final thumbnail = post.thumbnail();

    final animate = PlayAnimations.maybeOf(context) ?? false;

    // final stickers = post.stickers(context);
    final child = WrapSelection(
      onPressed: () {
        final fnc = OnBooruTagPressed.of(context);
        final idx = ThisIndex.of(context);

        final source = post.getSource(context);

        void tryScrollTo(int i) {}

        final sink = TrackedIndex.sinkOf(context);

        CardDialog.open(
          context,
          CardDialogData(
            onPressed: fnc,
            tryScrollTo: tryScrollTo,
            source: source,
            indexSink: sink,
            startingIdx: idx.$1,
          ),
        );
      },
      onDoubleTap: DownloadManager.available && LocalTagsService.available
          ? (context) {
              const downloadManager = DownloadManager();
              final status = downloadManager.statusFor(post.fileDownloadUrl());
              final downloadStatus = status?.data.status;

              if (downloadStatus == DownloadStatus.failed) {
                downloadManager.restartAll([status!]);
              } else {
                post.download();
              }
              WrapperSelectionAnimation.tryPlayOf(context);
            }
          : null,
      child: Builder(
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
                if (FavoritePostSourceService.available &&
                    widget.post is! FavoritePost)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: FavoritePostButton(
                      heroKey: (post.uniqueKey(), "favoritePost"),
                      post: post,
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
                      uniqueKey: widget.post.uniqueKey(),
                      isVideo: widget.post.type == PostContentType.video,
                      isGif: widget.post.type == PostContentType.gif,
                    ),
                  ),
                ),
                if (DownloadManager.available)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: LinearDownloadIndicator(
                      post: post,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (animate) {
      return child.animate(key: post.uniqueKey()).fadeIn();
    }

    return child;
  }
}

class CardAnimationChild extends StatelessWidget {
  const CardAnimationChild({
    super.key,
    required this.post,
    required this.animation,
    required this.buttonsRow,
  });

  final Animation<double>? animation;

  final PostImpl post;

  final Widget buttonsRow;

  @override
  Widget build(BuildContext context) {
    final thumbnail = post.thumbnail();
    final theme = Theme.of(context);

    final icon = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: SizedBox.expand(
        child: Center(
          child: Hero(
            tag: (post.uniqueKey(), "videoIcon"),
            child: const Icon(Icons.play_arrow_rounded),
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: clampDouble(
          360 * (post.height / post.width),
          240 * (post.height / post.width),
          420 * (post.height / post.width),
        ).clamp(0, 460),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // final content = post.content(context);

                SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.immersiveSticky,
                );
                const WindowApi().setWakelock(true);

                Navigator.of(context, rootNavigator: true)
                    .push<void>(
                  PageRouteBuilder(
                    barrierDismissible: true,
                    fullscreenDialog: true,
                    barrierColor: Colors.black.withValues(alpha: 1),
                    pageBuilder: (context, animation, animationSecond) {
                      return _BigImageVideo(post: post);
                    },
                  ),
                )
                    .then((_) {
                  const WindowApi().setWakelock(false);
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                });
              },
              child: Stack(
                children: [
                  GridCellImage(
                    backgroundColor: theme.colorScheme.surfaceContainerHigh
                        .withValues(alpha: 1),
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
                  if (post.type == PostContentType.video)
                    if (animation != null)
                      AnimatedBuilder(
                        animation: animation!,
                        builder: (context, child) => Opacity(
                          opacity: animation!.value,
                          child: child,
                        ),
                        child: icon,
                      )
                    else
                      icon,
                ],
              ),
            ),
          ),
          buttonsRow,
        ],
      ),
    );
  }
}

enum ReplaceAnimationType {
  vertical,
  horizontal,
}

class ReplaceAnimation extends StatefulWidget {
  const ReplaceAnimation({
    super.key,
    required this.source,
    required this.currentIndex,
    this.synchronizeRecv,
    this.synchronizeSnd,
    this.type = ReplaceAnimationType.horizontal,
    this.addScale = false,
    required this.child,
  });

  final ResourceSource<int, PostImpl> source;

  final int currentIndex;

  final Stream<(int, double?)>? synchronizeRecv;
  final Sink<(int, double?)>? synchronizeSnd;

  final ReplaceAnimationType type;

  final bool addScale;

  final Widget Function(BuildContext, int) child;

  @override
  State<ReplaceAnimation> createState() => _ReplaceAnimationState();
}

class _ReplaceAnimationState extends State<ReplaceAnimation>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<(int, double?)>? syncEvents;

  double? _animValue;
  int _idx = 0;

  double? get animValue => _animValue;
  set animValue(double? a) {
    _animValue = a;

    widget.synchronizeSnd?.add((_idx, _animValue));
  }

  int get idx => _idx;
  set idx(int i) {
    _idx = i;

    widget.synchronizeSnd?.add((_idx, _animValue));
  }

  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    idx = widget.currentIndex;

    syncEvents = widget.synchronizeRecv?.listen((e) {
      setState(() {
        idx = e.$1;
        animValue = e.$2;
      });
    });

    controller = AnimationController(
      value: 0,
      lowerBound: -1,
      duration: Durations.long4,
      vsync: this,
    );

    controller.addListener(listener);
  }

  @override
  void dispose() {
    syncEvents?.cancel();
    controller.removeListener(listener);
    controller.dispose();

    super.dispose();
  }

  void listener() {
    setState(() {
      animValue = controller.value;
    });
  }

  void commitForward([double? overrideFrom]) {
    if (controller.isAnimating || controller.value < -0.8) {
      return;
    }

    controller.value = overrideFrom ?? -0.8;
    controller.animateTo(-1, curve: Easing.emphasizedDecelerate).then((_) {
      controller.value = 0;
      setState(() {
        idx += 1;
      });
    });
  }

  void commitBackward([double? overrideFrom]) {
    if (controller.isAnimating || controller.value > 0.8) {
      return;
    }

    controller.value = overrideFrom ?? 0.8;
    controller.animateTo(1, curve: Easing.emphasizedDecelerate).then((_) {
      controller.value = 0;
      setState(() {
        idx -= 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Durations.medium1,
      curve: Easing.standard,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (idx != 0)
            Opacity(
              opacity: animValue != null && !animValue!.isNegative
                  ? animValue?.abs() ?? 0
                  : 0,
              child: widget.addScale
                  ? Transform.scale(
                      alignment: Alignment.centerLeft,
                      scale: (animValue?.abs() ?? 0).clamp(0.5, 1),
                      child: animValue != null &&
                              animValue != 0 &&
                              !animValue!.isNegative
                          ? widget.child(context, idx - 1)
                          : const SizedBox.shrink(),
                    )
                  : animValue != null &&
                          animValue != 0 &&
                          !animValue!.isNegative
                      ? widget.child(context, idx - 1)
                      : const SizedBox.shrink(),
            ),
          Opacity(
            opacity: animValue == null ? 1 : 1 - (animValue!.abs()),
            child: SlideTransition(
              position: AlwaysStoppedAnimation(
                switch (widget.type) {
                  ReplaceAnimationType.vertical => Offset(0, animValue ?? 0),
                  ReplaceAnimationType.horizontal => Offset(animValue ?? 0, 0),
                },
              ),
              child: GestureDetector(
                key: ValueKey(idx),
                onHorizontalDragEnd: widget.synchronizeRecv == null
                    ? (details) {
                        if (animValue != null &&
                            animValue!.isNegative &&
                            animValue! <= -0.5) {
                          commitForward(
                            animValue! < -0.95
                                ? animValue?.roundToDouble()
                                : animValue,
                          );

                          return;
                        } else if (animValue != null &&
                            !animValue!.isNegative &&
                            animValue! >= 0.5) {
                          commitBackward(
                            animValue! > 0.95
                                ? animValue?.roundToDouble()
                                : animValue,
                          );

                          return;
                        }

                        if (details.velocity.pixelsPerSecond.dx > 700 &&
                            animValue != null &&
                            idx != 0) {
                          commitBackward(animValue);

                          return;
                        } else if (details.velocity.pixelsPerSecond.dx < -700 &&
                            animValue != null &&
                            widget.source.count > 1 &&
                            widget.source.count - 1 != idx) {
                          commitForward(animValue);

                          return;
                        }

                        if (animValue != null) {
                          controller.value = animValue!;
                          controller.animateTo(0, curve: Easing.standard);
                        }
                      }
                    : null,
                onHorizontalDragUpdate: widget.synchronizeRecv == null
                    ? (details) {
                        if (animValue != null && idx == 0 && animValue! > 0.2) {
                          animValue = animValue!.clamp(0, 0.2);

                          return;
                        } else if (animValue != null &&
                            widget.source.count >= 1 &&
                            widget.source.count - 1 == idx &&
                            animValue! <= -0.2) {
                          animValue = animValue!.clamp(-0.2, 0);

                          return;
                        }

                        // if (animValue != null &&
                        //     animValue!.isNegative &&
                        //     animValue! < -0.8) {
                        //   commitForward();
                        //   return;
                        // } else if (animValue != null &&
                        //     !animValue!.isNegative &&
                        //     animValue! > 0.8) {
                        //   commitBackward();
                        //   return;
                        // }

                        setState(() {
                          animValue =
                              ((animValue ?? 0) + (details.delta.dx * 0.0034))
                                  .clamp(-1.0, 1.0);

                          if (widget.source.count - 1 == idx &&
                              animValue! < 0) {
                            animValue = animValue!.clamp(-0.2, 0);
                          } else if (idx == 0 && animValue! > 0) {
                            animValue = animValue!.clamp(0, 0.2);
                          }
                        });
                      }
                    : null,
                child: widget.child(context, idx),
              ),
            ),
          ),
          if (widget.source.count > 1 && widget.source.count - 1 != idx)
            Opacity(
              opacity: animValue != null && animValue!.isNegative
                  ? animValue?.abs() ?? 0
                  : 0,
              child: widget.addScale
                  ? Transform.scale(
                      alignment: Alignment.centerRight,
                      scale: (animValue?.abs() ?? 0).clamp(0.5, 1),
                      child: animValue != null &&
                              animValue != 0 &&
                              animValue!.isNegative
                          ? widget.child(context, idx + 1)
                          : const SizedBox.shrink(),
                    )
                  : animValue != null && animValue != 0 && animValue!.isNegative
                      ? widget.child(context, idx + 1)
                      : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class CardDialogStaticData {
  const CardDialogStaticData({
    required this.onPressed,
    required this.booru,
    required this.postId,
  });

  final OnBooruTagPressedFunc onPressed;

  final Booru booru;
  final int postId;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType || other is! CardDialogStaticData) {
      return false;
    }

    return postId == other.postId &&
        onPressed == other.onPressed &&
        booru == other.booru;
  }

  @override
  int get hashCode => Object.hash(
        postId,
        onPressed,
        booru,
      );
}

class CardDialogStatic extends StatelessWidget {
  const CardDialogStatic({
    super.key,
    required this.getPost,
    required this.animation,
  });

  final Animation<double>? animation;

  final Future<PostImpl> Function() getPost;

  static void openAsync(
    BuildContext context, {
    required Booru booru,
    required int postId,
  }) {
    if (!TagManagerService.available || !VisitedPostsService.available) {
      addAlert("openPostAsync", "Couldn't launch image view"); // TODO: change

      return;
    }

    final fnc = OnBooruTagPressed.of(context);

    context.pushNamed(
      "PostImageAsync",
      extra: CardDialogStaticData(
        onPressed: fnc,
        booru: booru,
        postId: postId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    void exit() {
      Navigator.of(context).pop();
    }

    final child = WrapFutureRestartable(
      newStatus: getPost,
      bottomSheetVariant: true,
      errorBuilder: (error, refresh) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400.0.clamp(0, size.width),
              maxHeight: 400.0.clamp(0, size.height),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              child: Material(
                type: MaterialType.card,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 38,
                  ),
                  child: WrapFutureRestartable.defaultError(
                    error,
                    refresh,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      placeholder: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400.0.clamp(0, size.width),
              maxHeight: 400.0.clamp(0, size.height),
            ),
            child: const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              child: ShimmerLoadingIndicator(backgroundAlpha: 1),
            ),
          ),
        ),
      ),
      builder: (context, post) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                child: CardAnimationChild(
                  animation: animation,
                  post: post,
                  buttonsRow: ClipRRect(
                    child: _ButtonsCol(
                      animation: animation,
                      post: post,
                    ),
                  ),
                ),
              ),
              _TagsRowBorder(
                animation: animation,
                child: _TagsRowSingle(
                  post: post,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return ExitOnPressRoute(
      exit: exit,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400.0.clamp(0, size.width),
          ),
          child: animation != null
              ? AnimatedBuilder(
                  animation: animation!,
                  builder: (context, child) => Opacity(
                    opacity: animation!.value,
                    child: child,
                  ),
                  child: child,
                )
              : child,
        ),
      ),
    );
  }
}

class CardDialogData {
  const CardDialogData({
    required this.onPressed,
    required this.tryScrollTo,
    required this.source,
    required this.indexSink,
    required this.startingIdx,
  });

  final OnBooruTagPressedFunc onPressed;
  final void Function(int) tryScrollTo;

  final ResourceSource<int, PostImpl> source;

  final Sink<int?> indexSink;

  final int startingIdx;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType || other is! CardDialogData) {
      return false;
    }

    return indexSink == other.indexSink &&
        onPressed == other.onPressed &&
        tryScrollTo == other.tryScrollTo &&
        source == other.source &&
        startingIdx == other.startingIdx;
  }

  @override
  int get hashCode => Object.hash(
        indexSink,
        onPressed,
        tryScrollTo,
        source,
        startingIdx,
      );
}

class CardDialog extends StatefulWidget {
  const CardDialog({
    super.key,
    required this.animation,
    required this.data,
  });

  final CardDialogData data;

  final Animation<double>? animation;

  static void open(BuildContext context, CardDialogData data) {
    context.pushNamed("PostImage", extra: data);
  }

  @override
  State<CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<CardDialog> {
  Animation<double>? get animation => widget.animation;

  int get idx => widget.data.startingIdx;
  ResourceSource<int, PostImpl> get source => widget.data.source;
  late final StreamSubscription<(int, double?)> _indexEvents;
  int _oldIdx = 0;

  final syncr = StreamController<(int, double?)>.broadcast();

  @override
  void initState() {
    super.initState();

    _oldIdx = widget.data.startingIdx;

    _indexEvents = syncr.stream.listen((e) {
      if (e.$1 != _oldIdx) {
        _oldIdx = e.$1;

        widget.data.indexSink.add(_oldIdx);

        widget.data.tryScrollTo(_oldIdx);

        if (context.mounted && source.count > 1) {
          if (_oldIdx != 0) {
            precacheImage(
              source.forIdxUnsafe(_oldIdx - 1).thumbnail(),
              // ignore: use_build_context_synchronously
              context,
            );
          }

          if (_oldIdx != source.count - 1) {
            precacheImage(
              source.forIdxUnsafe(_oldIdx + 1).thumbnail(),
              // ignore: use_build_context_synchronously
              context,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _indexEvents.cancel();

    super.dispose();
  }

  void _exit() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return ExitOnPressRoute(
      exit: _exit,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400.0.clamp(0, size.width),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Column(
                // mainAxisSize: MainAxisSize.max,
                children: [
                  ClipRRect(
                    child: ReplaceAnimation(
                      source: source,
                      synchronizeSnd: syncr.sink,
                      addScale: true,
                      currentIndex: idx,
                      child: (context, idx) {
                        return CardAnimationChild(
                          post: source.forIdxUnsafe(idx),
                          animation: animation,
                          buttonsRow: ClipRRect(
                            child: ReplaceAnimation(
                              source: source,
                              synchronizeRecv: syncr.stream,
                              currentIndex: idx,
                              type: ReplaceAnimationType.vertical,
                              child: (context, idx) {
                                return _ButtonsCol(
                                  animation: animation,
                                  post: source.forIdxUnsafe(idx),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _TagsRow(
                    idx: idx,
                    syncr: syncr,
                    animation: animation,
                    source: source,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonsCol extends StatelessWidget {
  const _ButtonsCol({
    super.key,
    required this.animation,
    required this.post,
  });

  final Animation<double>? animation;
  final PostImpl post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final infoIcon = IconButton(
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) {
            return Padding(
              padding: EdgeInsets.only(
                top: 8,
                bottom: MediaQuery.viewPaddingOf(
                      context,
                    ).bottom +
                    12,
              ),
              child: SizedBox(
                width: MediaQuery.sizeOf(
                  sheetContext,
                ).width,
                child: PostInfoSimple(post: post),
              ),
            );
          },
        );
      },
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          theme.colorScheme.surface,
        ),
        backgroundColor: WidgetStatePropertyAll(
          theme.colorScheme.onSurfaceVariant,
        ),
      ),
      icon: const Icon(Icons.info_outline),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // spacing: 8,
          children: [
            // const SizedBox.shrink(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      if (FavoritePostSourceService.available)
                        if (animation != null)
                          AnimatedBuilder(
                            animation: animation!,
                            builder: (context, child) => Opacity(
                              opacity: animation!.value,
                              child: child,
                            ),
                            child: StarsButton(
                              addBackground: true,
                              idBooru: (post.id, post.booru),
                            ),
                          )
                        else
                          StarsButton(
                            addBackground: true,
                            idBooru: (post.id, post.booru),
                          ),
                      if (DownloadManager.available &&
                          LocalTagsService.available)
                        if (animation != null)
                          AnimatedBuilder(
                            animation: animation!,
                            builder: (context, child) => Opacity(
                              opacity: animation!.value,
                              child: child,
                            ),
                            child: DownloadButton(
                              post: post,
                              secondVariant: true,
                            ),
                          )
                        else
                          DownloadButton(
                            post: post,
                            secondVariant: true,
                          ),
                      if (FavoritePostSourceService.available &&
                          post is! FavoritePost)
                        FavoritePostButton(
                          heroKey: (post.uniqueKey(), "favoritePost"),
                          post: post,
                          backgroundAlpha: 1,
                        )
                      else if (FavoritePostSourceService.available)
                        if (animation != null)
                          AnimatedBuilder(
                            animation: animation!,
                            builder: (context, child) => Opacity(
                              opacity: animation!.value,
                              child: child,
                            ),
                            child: FavoritePostButton(
                              post: post,
                              backgroundAlpha: 1,
                            ),
                          )
                        else
                          FavoritePostButton(
                            post: post,
                            backgroundAlpha: 1,
                          ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: animation != null
                  ? AnimatedBuilder(
                      animation: animation!,
                      builder: (context, child) => Opacity(
                        opacity: animation!.value,
                        child: child,
                      ),
                      child: infoIcon,
                    )
                  : infoIcon,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagsRow extends StatefulWidget {
  const _TagsRow({
    // super.key,
    required this.idx,
    required this.syncr,
    required this.source,
    required this.animation,
  });

  final int idx;

  final Animation<double>? animation;

  final StreamController<(int, double?)> syncr;
  final ResourceSource<int, PostImpl> source;

  @override
  State<_TagsRow> createState() => _TagsRowState();
}

mixin _MultipleSortedTagArray<W extends StatefulWidget> on State<W> {
  StreamController<(int, double?)>? get syncr;
  int get initIdx;

  int get count;
  int get index => _idx;

  PostImpl getPost(int idx);

  StreamSubscription<int> Function(void Function(int) f)? get countEvents;

  (Map<String, void>, int) _pinnedTags = ({}, 0);
  final Map<int, List<({String tag, bool pinned})>> _values = {};

  int _idx = 0;

  late final StreamSubscription<(int, double?)>? _events;
  late final StreamSubscription<int>? _countEvents;

  List<({String tag, bool pinned})> getTags(int idx) => _values[idx]!;

  @override
  void initState() {
    super.initState();

    _idx = initIdx;

    _events = syncr?.stream.listen((e) {
      if (e.$1 != _idx) {
        _setIdx(e.$1);

        setState(() {});
      }
    });

    _countEvents = countEvents?.call((_) {
      _setIdx(_idx);

      setState(() {});
    });

    _setIdx(_idx);
  }

  (int, int, int) _clampTriplet((int, int, int) tuple) {
    return (
      tuple.$1.clamp(0, count - 1),
      tuple.$2,
      tuple.$3.clamp(0, count - 1)
    );
  }

  Set<int> _toSet((int, int, int) tuple) {
    return <int>{}
      ..add(tuple.$1)
      ..add(tuple.$2)
      ..add(tuple.$3);
  }

  void _setIdx(int newIdx) {
    final oldTriple = _clampTriplet((_idx - 1, _idx, _idx + 1));
    final newTriple = _clampTriplet((newIdx - 1, newIdx, newIdx + 1));

    if (oldTriple == newTriple) {
      for (final e in _toSet(oldTriple)) {
        if (!_values.containsKey(e)) {
          _values[e] = _sortTags(e);
        }
      }

      return;
    }

    final oldSet = _toSet(oldTriple);
    final newSet = _toSet(newTriple);

    final toDelete = oldSet.difference(newSet);
    final toAdd = newSet.difference(oldSet);

    for (final e in toDelete) {
      _values.remove(e);
    }

    for (final e in toAdd) {
      if (!_values.containsKey(e)) {
        _values[e] = _sortTags(e);
      }
    }

    _idx = newIdx;
  }

  List<({String tag, bool pinned})> _sortTags(int idx) {
    final postTags = getPost(idx).tags;

    if (_pinnedTags.$1.isEmpty) {
      return postTags.map((e) => (tag: e, pinned: false)).toList();
    }

    final postTags_ = postTags.toList();
    final pinnedTags = <String>[];
    postTags_.removeWhere((e) {
      if (_pinnedTags.$1.containsKey(e)) {
        pinnedTags.add(e);

        return true;
      }

      return false;
    });

    return pinnedTags
        .map((e) => (tag: e, pinned: true))
        .followedBy(postTags_.map((e) => (tag: e, pinned: false)))
        .toList();
  }

  void _resortMap() {
    for (final e in _values.keys) {
      _values[e] = _sortTags(e);
    }
  }

  @override
  void dispose() {
    _events?.cancel();
    _countEvents?.cancel();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final pinnedTags = PinnedTagsProvider.of(context);
    if (pinnedTags != _pinnedTags) {
      _pinnedTags = pinnedTags;

      _resortMap();
    }
  }
}

class _TagsRowBorder extends StatelessWidget {
  const _TagsRowBorder({
    super.key,
    this.post,
    required this.animation,
    required this.child,
  });

  final PostImpl? post;

  final Animation<double>? animation;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget clipRrect = ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: child,
        ),
      ),
    );

    if (post != null) {
      clipRrect = Hero(
        tag: (post!.uniqueKey(), "tags"),
        child: clipRrect,
      );
    }

    final cliprr = Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 25 + 16),
        child: Padding(
          padding: EdgeInsets.zero,
          child: clipRrect,
        ),
      ),
    );

    if (animation == null) {
      return cliprr;
    }

    return AnimatedBuilder(
      animation: animation!,
      builder: (context, child) => Opacity(
        opacity: animation!.value,
        child: child,
      ),
      child: cliprr,
    );
  }
}

class _TagsRowSingle extends StatefulWidget {
  const _TagsRowSingle({
    super.key,
    required this.post,
  });

  final PostImpl post;

  @override
  State<_TagsRowSingle> createState() => __TagsRowSingleState();
}

class __TagsRowSingleState extends State<_TagsRowSingle>
    with PinnedSortedTagsArrayMixin {
  @override
  List<String> get postTags => widget.post.tags;

  @override
  Widget build(BuildContext context) {
    return _TagsRowChild(
      post: widget.post,
      tags: tags,
    );
  }
}

class _TagsRowState extends State<_TagsRow> with _MultipleSortedTagArray {
  @override
  StreamSubscription<int> Function(void Function(int) f) get countEvents =>
      widget.source.backingStorage.watch;

  @override
  int get count => widget.source.count;

  @override
  PostImpl getPost(int idx) => widget.source.forIdxUnsafe(idx);

  @override
  int get initIdx => widget.idx;

  @override
  StreamController<(int, double?)> get syncr => widget.syncr;

  @override
  Widget build(BuildContext context) {
    return _TagsRowBorder(
      post: getPost(index),
      animation: widget.animation,
      child: ReplaceAnimation(
        source: widget.source,
        synchronizeRecv: widget.syncr.stream,
        currentIndex: widget.idx,
        child: (context, idx) {
          return _TagsRowChild(
            post: getPost(idx),
            tags: getTags(idx),
          );
        },
      ),
    );
  }
}

class _TagsRowChild extends StatelessWidget {
  const _TagsRowChild({
    super.key,
    required this.post,
    required this.tags,
  });

  final PostImpl post;
  final List<({bool pinned, String tag})> tags;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.antiAlias,
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final e = tags[index];

        return Center(
          child: OutlinedTagChip(
            tag: e.tag,
            isPinned: e.pinned,
            letterCount: -1,
            onDoublePressed: e.pinned || !TagManagerService.available
                ? null
                : () {
                    // controller.animateTo(
                    //   0,
                    //   duration: Durations.medium3,
                    //   curve: Easing.standard,
                    // );

                    const TagManagerService().pinned.add(e.tag);
                  },
            onLongPressed: post is FavoritePost
                ? null
                : () {
                    context.openSafeModeDialog((safeMode) {
                      OnBooruTagPressed.pressOf(
                        context,
                        e.tag,
                        post.booru,
                        overrideSafeMode: safeMode,
                      );
                    });
                  },
            onPressed: () => OnBooruTagPressed.pressOf(
              context,
              e.tag,
              post.booru,
            ),
          ),
        );
      },
    );
  }
}

class _BigImageVideo extends StatelessWidget {
  const _BigImageVideo({
    super.key,
    required this.post,
  });

  final PostImpl post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget child = switch (post.type) {
      PostContentType.none => const SizedBox.shrink(),
      PostContentType.video => Material(
          child: _ExpandedVideo(
            post: post,
            child: PhotoGalleryPageVideo(
              url: post.videoUrl(),
              networkThumb: post.thumbnail(),
              localVideo: false,
            ),
          ),
        ),
      PostContentType.gif || PostContentType.image => PhotoView(
          heroAttributes: PhotoViewHeroAttributes(tag: post.uniqueKey()),
          maxScale: PhotoViewComputedScale.contained * 1.8,
          minScale: PhotoViewComputedScale.contained * 0.8,
          filterQuality: FilterQuality.high,
          loadingBuilder: (context, event) {
            final theme = Theme.of(context);

            final t = post.thumbnail();

            final expectedBytes = event?.expectedTotalBytes;
            final loadedBytes = event?.cumulativeBytesLoaded;
            final value = loadedBytes != null && expectedBytes != null
                ? loadedBytes / expectedBytes
                : null;

            return Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Image(
                  image: t,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.contain,
                ),
                Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.onSurfaceVariant,
                    backgroundColor: theme.colorScheme.surfaceContainer
                        .withValues(alpha: 0.4),
                    value: value ?? 0,
                  ),
                ),
              ],
            );
          },
          backgroundDecoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0),
          ),
          imageProvider: post.imageContent(),
        ),
    };

    return child;
  }
}

class _ExpandedVideo extends StatefulWidget {
  const _ExpandedVideo({
    // super.key,
    required this.post,
    required this.child,
  });

  final PostImpl post;

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
                    forceShow: true,
                    videoControls: videoControls,
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

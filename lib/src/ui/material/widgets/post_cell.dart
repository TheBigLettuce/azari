// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:ui";

import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/resource_source/chained_filter.dart";
import "package:azari/src/logic/resource_source/filtering_mode.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/base/home.dart";
import "package:azari/src/ui/material/pages/home/booru_page.dart";
import "package:azari/src/ui/material/widgets/gesture_dead_zones.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/ui/material/widgets/image_view/video/photo_gallery_page_video.dart";
import "package:azari/src/ui/material/widgets/image_view/video/player_widget_controller.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:azari/src/ui/material/widgets/radio_dialog.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/list_layout.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_placeholders.dart";
import "package:azari/src/ui/material/widgets/wrap_future_restartable.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photo_view/photo_view.dart";
import "package:photo_view/photo_view_gallery.dart";

class PostCell extends StatefulWidget {
  const PostCell({
    required super.key,
    required this.cellType,
    required this.post,
    required this.toBlur,
  });

  final CellType cellType;
  final bool toBlur;
  final PostImpl post;

  @override
  State<PostCell> createState() => _PostCellState();
}

class _PostCellState extends State<PostCell>
    with PinnedSortedTagsArrayMixin, SettingsWatcherMixin {
  PostImpl get post => widget.post;
  @override
  List<String> get postTags => widget.post.tags;

  late final name = widget.post.tags.join(" ");

  final controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void _open() {
    final fnc = OnBooruTagPressed.of(context);
    final idx = ThisIndex.of(context);

    final source = post.getSource(context);

    void tryScrollTo(int i) {}

    final sink = TrackedIndex.sinkOf(context);

    const VisitedPostsService().addAll([post.asVisitedPost]);

    Navigator.of(context, rootNavigator: true)
        .push<void>(
          PageRouteBuilder(
            barrierDismissible: true,
            fullscreenDialog: true,
            opaque: false,
            barrierColor: Colors.black.withValues(alpha: 0.2),
            pageBuilder: (context, animation, secondaryAnimation) {
              return OnBooruTagPressed(
                onPressed: fnc,
                child: CardDialog(
                  animation: animation,
                  source: source,
                  indexSink: sink,
                  tryScrollTo: tryScrollTo,
                  idx: idx.$1,
                ),
              );
            },
          ),
        )
        .whenComplete(() {
          sink.add(null);
        });
  }

  void _download(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = post.thumbnail();

    final animate = PlayAnimations.maybeOf(context) ?? false;

    final sortingColor =
        ChainedFilterResourceSource.maybeOf(context)?.sortingMode ==
        SortingMode.color;

    Widget child = WrapSelection(
      onPressed: _open,
      onDoubleTap: DownloadManager.available && LocalTagsService.available
          ? _download
          : null,
      child: switch (widget.cellType) {
        CellType.list => DefaultListTile(
          uniqueKey: widget.post.uniqueKey(),
          thumbnail: thumbnail,
          title: name,
        ),
        CellType.cell => Builder(
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
                    thumbnail:
                        post.type == PostContentType.gif &&
                            post.size != 0 &&
                            !post.size.isNegative &&
                            post.size < 524288
                        ? CachedNetworkImageProvider(
                            post.sampleUrl.isEmpty
                                ? post.fileUrl
                                : post.sampleUrl,
                          )
                        : thumbnail,
                    blur: widget.toBlur,
                  ),
                  if (FavoritePostSourceService.available &&
                      widget.post is! FavoritePost)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: FavoritePostButton(
                          heroKey: (post.uniqueKey(), "favoritePost"),
                          post: post,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sortingColor && post is FavoritePost)
                            Builder(
                              builder: (context) {
                                return ColorCube(
                                  idBooru: (post.id, post.booru),
                                  source:
                                      ResourceSource.maybeOf<int, FavoritePost>(
                                        context,
                                      ),
                                );
                              },
                            ),
                          VideoOrGifIcon(
                            uniqueKey: post.uniqueKey(),
                            type: post.type,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (DownloadManager.available)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearDownloadIndicator(post: post),
                    ),
                ],
              ),
            ),
          ),
        ),
      },
    );

    if (animate) {
      child = child.animate(key: widget.post.uniqueKey()).fadeIn();
    }

    return child;
  }
}

class CardAnimationChild extends StatelessWidget {
  const CardAnimationChild({
    super.key,
    required this.post,
    required this.animation,
    required this.source,
    required this.thisIdx,
    required this.tryScrollTo,
  });

  final Animation<double> animation;
  final ResourceSource<int, PostImpl>? source;

  final int thisIdx;
  final PostImpl post;

  final void Function(int)? tryScrollTo;

  void _open(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    const WindowApi().setWakelock(true);

    Navigator.of(context, rootNavigator: true)
        .push<void>(
          PageRouteBuilder(
            barrierDismissible: true,
            fullscreenDialog: true,
            barrierColor: Colors.black.withValues(alpha: 1),
            pageBuilder: (context, animation, animationSecond) {
              return CardDialogContent(
                source: source,
                startingIdx: thisIdx,
                tryScrollTo: tryScrollTo,
                post: source == null ? post : null,
              );
            },
          ),
        )
        .then((_) {
          const WindowApi().setWakelock(false);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        });
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = post.thumbnail();
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: clampDouble(
          360 * (post.height / post.width),
          240 * (post.height / post.width),
          420 * (post.height / post.width),
        ).clamp(0, 460),
      ),
      child: GestureDetector(
        onTap: () => _open(context),
        child: Stack(
          children: [
            GridCellImage(
              backgroundColor: theme.colorScheme.surfaceContainerHigh
                  .withValues(alpha: 1),
              heroTag: post.uniqueKey(),
              imageAlign: Alignment.topCenter,
              thumbnail:
                  post.type == PostContentType.gif &&
                      post.size != 0 &&
                      !post.size.isNegative &&
                      post.size < 524288
                  ? CachedNetworkImageProvider(
                      post.sampleUrl.isEmpty ? post.fileUrl : post.sampleUrl,
                    )
                  : thumbnail,
              blur: false,
            ),
            if (post.type == PostContentType.video)
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) =>
                    Opacity(opacity: animation.value, child: child),
                child: DecoratedBox(
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
                ),
              ),
            if (FavoritePostSourceService.available)
              Align(
                alignment: Alignment.topRight,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) =>
                      Opacity(opacity: animation.value, child: child),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: ColorCube(
                      idBooru: (post.id, post.booru),
                      source: source,
                    ),
                  ),
                ),
              ),
            if (post is FavoritePost)
              RefreshImageCube(
                post: post as FavoritePost,
                animation: animation,
              ),
          ],
        ),
      ),
    );
  }
}

class RefreshImageCube extends StatelessWidget {
  const RefreshImageCube({
    super.key,
    required this.post,
    required this.animation,
  });

  final FavoritePost post;
  final Animation<double> animation;

  Future<void> _fetchUpdate() async {
    final api = BooruAPI.fromEnum(post.booru);

    try {
      final newPost = await api.singlePost(post.id);
      post.applyBase(newPost).maybeSave();
    } catch (e, stack) {
      AlertService().add(
        AlertData("_RefreshImageCube", stack.toString(), null),
      );
    } finally {
      api.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final status = const TasksService().status<RefreshImageCube>(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) =>
          Opacity(opacity: animation.value, child: child),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withValues(
                alpha: 0.8,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                onTap: status == TaskStatus.done
                    ? () => const TasksService().add<RefreshImageCube>(
                        _fetchUpdate,
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: status == TaskStatus.done ? 0.8 : 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ReplaceAnimationType { vertical, horizontal }

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
  State<ReplaceAnimation> createState() => ReplaceAnimationState();
}

class ReplaceAnimationState extends State<ReplaceAnimation>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<(int, double?)>? syncEvents;
  late final StreamSubscription<int> _countEvents;

  double? _animValue;
  int _idx = 0;
  int _count = 0;

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
    _count = widget.source.backingStorage.count;

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

    _countEvents = widget.source.backingStorage.watch((count) {
      setState(() {
        idx = count == 0 || count == 1 ? 0 : idx.clamp(0, count - 1);
        _count = count;
      });
    });

    controller.addListener(listener);
  }

  @override
  void dispose() {
    syncEvents?.cancel();
    controller.removeListener(listener);
    controller.dispose();
    _countEvents.cancel();

    super.dispose();
  }

  void listener() {
    setState(() {
      animValue = controller.value;
    });
  }

  void next() {
    if (widget.source.count == 0 ||
        widget.source.count == 1 ||
        idx + 1 >= widget.source.count) {
      return;
    }

    commitForward();
  }

  void prev() {
    if (widget.source.count == 0 || widget.source.count == 1 || idx == 0) {
      return;
    }

    commitBackward();
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
    if (_count == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: Durations.medium1,
      curve: Easing.standard,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (idx != 0)
            switch (widget.type) {
              ReplaceAnimationType.vertical => Opacity(
                opacity: animValue != null && !animValue!.isNegative
                    ? animValue?.abs() ?? 0
                    : 0,
                child: SlideTransition(
                  position: AlwaysStoppedAnimation(
                    Offset(0, 1 - (animValue ?? 0)),
                  ),
                  child: widget.addScale
                      ? Transform.scale(
                          alignment: Alignment.centerLeft,
                          scale: (animValue?.abs() ?? 0).clamp(0.5, 1),
                          child:
                              animValue != null &&
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
              ),

              ReplaceAnimationType.horizontal => Opacity(
                opacity: animValue != null && !animValue!.isNegative
                    ? animValue?.abs() ?? 0
                    : 0,
                child: widget.addScale
                    ? Transform.scale(
                        alignment: Alignment.centerLeft,
                        scale: (animValue?.abs() ?? 0).clamp(0.5, 1),
                        child:
                            animValue != null &&
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
            },
          Opacity(
            opacity: animValue == null ? 1 : 1 - (animValue!.abs()),
            child: SlideTransition(
              position: AlwaysStoppedAnimation(switch (widget.type) {
                ReplaceAnimationType.vertical => Offset(0, animValue ?? 0),
                ReplaceAnimationType.horizontal => Offset(animValue ?? 0, 0),
              }),
              child: GestureDetector(
                key: ValueKey((idx, _count)),
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
            switch (widget.type) {
              ReplaceAnimationType.vertical => Opacity(
                opacity: animValue != null && animValue!.isNegative
                    ? animValue?.abs() ?? 0
                    : 0,
                child: SlideTransition(
                  position: AlwaysStoppedAnimation(
                    Offset(0, -1 - (animValue ?? 0)),
                  ),
                  child: widget.addScale
                      ? Transform.scale(
                          alignment: Alignment.centerRight,
                          scale: (animValue?.abs() ?? 0).clamp(0.5, 1),
                          child:
                              animValue != null &&
                                  animValue != 0 &&
                                  animValue!.isNegative
                              ? widget.child(context, idx + 1)
                              : const SizedBox.shrink(),
                        )
                      : animValue != null &&
                            animValue != 0 &&
                            animValue!.isNegative
                      ? widget.child(context, idx + 1)
                      : const SizedBox.shrink(),
                ),
              ),
              ReplaceAnimationType.horizontal => Opacity(
                opacity: animValue != null && animValue!.isNegative
                    ? animValue?.abs() ?? 0
                    : 0,
                child: widget.addScale
                    ? Transform.scale(
                        alignment: Alignment.centerRight,
                        scale: (animValue?.abs() ?? 0).clamp(0.5, 1),
                        child:
                            animValue != null &&
                                animValue != 0 &&
                                animValue!.isNegative
                            ? widget.child(context, idx + 1)
                            : const SizedBox.shrink(),
                      )
                    : animValue != null &&
                          animValue != 0 &&
                          animValue!.isNegative
                    ? widget.child(context, idx + 1)
                    : const SizedBox.shrink(),
              ),
            },
        ],
      ),
    );
  }
}

class CardDialogStatic extends StatelessWidget {
  const CardDialogStatic({
    super.key,
    required this.getPost,
    required this.animation,
  });

  final Animation<double> animation;

  final Future<PostImpl> Function() getPost;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    void exit() {
      Navigator.of(context).pop();
    }

    return ExitOnPressRoute(
      exit: exit,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400.0.clamp(0, size.width)),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) =>
                Opacity(opacity: animation.value, child: child),
            child: WrapFutureRestartable(
              newStatus: getPost,
              bottomSheetVariant: true,
              errorBuilder: (error, refresh) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
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
                          child: WrapFutureRestartable.defaultErrorBuilder(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              child: CardAnimationChild(
                                animation: animation,
                                post: post,
                                thisIdx: 0,
                                tryScrollTo: null,
                                source: null,
                              ),
                            ),
                          ),
                          ClipRRect(
                            child: CardDialogButtons(
                              animation: animation,
                              post: post,
                            ),
                          ),
                        ],
                      ),
                      _TagsRowBorder(
                        animation: animation,
                        child: _TagsRowSingle(post: post),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GoForwardIntent extends Intent {
  const GoForwardIntent();
}

class GoBackwardIntent extends Intent {
  const GoBackwardIntent();
}

class GoForwardAction extends Action<GoForwardIntent> {
  GoForwardAction(this.forward);

  final VoidCallback forward;

  @override
  void invoke(GoForwardIntent intent) => forward();
}

class GoBackwardAction extends Action<GoBackwardIntent> {
  GoBackwardAction(this.backward);

  final VoidCallback backward;

  @override
  void invoke(GoBackwardIntent intent) => backward();
}

class CardDialog extends StatefulWidget {
  const CardDialog({
    super.key,
    required this.animation,
    required this.idx,
    required this.source,
    required this.tryScrollTo,
    required this.indexSink,
  });

  final Animation<double> animation;

  final void Function(int) tryScrollTo;

  final int idx;
  final ResourceSource<int, PostImpl> source;

  final Sink<int?> indexSink;

  @override
  State<CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<CardDialog> {
  Animation<double> get animation => widget.animation;

  final _mainKey = GlobalKey<ReplaceAnimationState>();

  int get idx => widget.idx;
  ResourceSource<int, PostImpl> get source => widget.source;
  late final StreamSubscription<(int, double?)> _indexEvents;
  late final StreamSubscription<int> _countEvents;

  int _oldIdx = 0;

  final syncr = StreamController<(int, double?)>.broadcast();

  late final _actions = <Type, Action<Intent>>{
    GoForwardIntent: GoForwardAction(() => _mainKey.currentState?.next()),
    GoBackwardIntent: GoBackwardAction(() => _mainKey.currentState?.prev()),
  };

  @override
  void initState() {
    super.initState();

    _oldIdx = widget.idx;

    _indexEvents = syncr.stream.listen((e) {
      if (e.$1 != _oldIdx) {
        _oldIdx = e.$1;

        final post = source.forIdx(e.$1);
        if (post != null) {
          const VisitedPostsService().addAll([post.asVisitedPost]);
        }

        widget.indexSink.add(_oldIdx);

        widget.tryScrollTo(_oldIdx);

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

    _countEvents = widget.source.backingStorage.watch((count) {
      if (count == 0) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _indexEvents.cancel();
    _countEvents.cancel();

    super.dispose();
  }

  void _exit() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    if (widget.source.count == 0) {
      return const SizedBox.shrink();
    }

    return Shortcuts(
      shortcuts: const <SingleActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowRight): GoForwardIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): GoBackwardIntent(),
      },
      child: ExitOnPressRoute(
        exit: _exit,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400.0.clamp(0, size.width)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            child: Actions(
                              actions: _actions,
                              child: Focus(
                                autofocus: true,
                                child: ReplaceAnimation(
                                  key: _mainKey,
                                  source: source,
                                  synchronizeSnd: syncr.sink,
                                  addScale: true,
                                  currentIndex: idx,
                                  child: (context, idx) {
                                    final post = source.forIdx(idx);
                                    if (post == null) {
                                      return const SizedBox.shrink();
                                    }

                                    return CardAnimationChild(
                                      post: post,
                                      animation: animation,
                                      thisIdx: idx,
                                      tryScrollTo: (idx) {
                                        _mainKey.currentState?.idx = idx;
                                        _mainKey.currentState?.setState(() {});
                                      },
                                      source: source,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        ClipRRect(
                          child: ReplaceAnimation(
                            source: source,
                            synchronizeRecv: syncr.stream,
                            currentIndex: idx,
                            type: ReplaceAnimationType.vertical,
                            child: (context, idx) {
                              final post = source.forIdx(idx);
                              if (post == null) {
                                return const SizedBox.shrink();
                              }

                              return CardDialogButtons(
                                animation: animation,
                                post: post,
                              );
                            },
                          ),
                        ),
                      ],
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
      ),
    );
  }
}

class CardDialogButtons extends StatelessWidget {
  const CardDialogButtons({
    super.key,
    required this.animation,
    required this.post,
  });

  final Animation<double> animation;
  final PostImpl post;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: clampDouble(
          360 * (post.height / post.width),
          240 * (post.height / post.width),
          420 * (post.height / post.width),
        ).clamp(0, 460),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        if (DownloadManager.available &&
                            LocalTagsService.available)
                          AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) =>
                                Opacity(opacity: animation.value, child: child),
                            child: DownloadButton(
                              post: post,
                              secondVariant: true,
                            ),
                          ),
                        if (FavoritePostSourceService.available &&
                            post is! FavoritePost)
                          FavoritePostButton(
                            heroKey: (post.uniqueKey(), "favoritePost"),
                            post: post,
                            backgroundAlpha: 1,
                          )
                        else if (FavoritePostSourceService.available)
                          AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) =>
                                Opacity(opacity: animation.value, child: child),
                            child: FavoritePostButton(
                              post: post,
                              backgroundAlpha: 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) =>
                      Opacity(opacity: animation.value, child: child),
                  child: ShowPostInfoButton(post: post),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShowPostInfoButton extends StatefulWidget {
  const ShowPostInfoButton({super.key, required this.post});

  final PostImpl post;

  @override
  State<ShowPostInfoButton> createState() => _ShowPostInfoButtonState();
}

class _ShowPostInfoButtonState extends State<ShowPostInfoButton>
    with FavoritePostsWatcherMixin {
  late FavoriteStars? stars;

  @override
  void onFavoritePostsUpdate() {
    super.onFavoritePostsUpdate();

    stars = const FavoritePostSourceService().cache.get((
      widget.post.id,
      widget.post.booru,
    ))?.stars;
  }

  @override
  void initState() {
    super.initState();

    onFavoritePostsUpdate();
  }

  void _openBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 8,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
          ),
          child: SizedBox(
            width: MediaQuery.sizeOf(sheetContext).width,
            child: PostInfo(post: widget.post),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSize(
      alignment: Alignment.topCenter,
      curve: Easing.standard,
      duration: Durations.long1,
      child: Column(
        children: [
          IconButton(
            onPressed: _openBottomSheet,
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(
                theme.colorScheme.surface,
              ),
              backgroundColor: WidgetStatePropertyAll(
                theme.colorScheme.onSurfaceVariant,
              ),
            ),
            icon: const Icon(Icons.info_outline),
          ),

          if (stars != null && stars! != FavoriteStars.zero)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Badge(
                offset: Offset.zero,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                alignment: Alignment.center,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        stars!.asNumber.toString(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.post.score >= 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: PhysicalModel(
                color: Colors.black87.withValues(alpha: 0.25),
                elevation: 4,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.thumb_up_alt_rounded,
                          size: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        widget.post.score.toString(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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

  final Animation<double> animation;

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

  PostImpl? getPost(int idx);

  StreamSubscription<int> Function(void Function(int) f)? get countEvents;

  ({Map<String, void> map, int count}) _pinnedTags = (map: {}, count: 0);
  final Map<int, List<({String tag, bool pinned})>> _values = {};

  int _idx = 0;
  int _prevCount = 0;

  late final StreamSubscription<(int, double?)>? _events;
  late final StreamSubscription<int>? _countEvents;

  List<({String tag, bool pinned})>? getTags(int idx) => _values[idx];

  @override
  void initState() {
    super.initState();

    _prevCount = count;
    _idx = initIdx;

    _events = syncr?.stream.listen((e) {
      if (e.$1 != _idx) {
        _setIdx(e.$1);

        setState(() {});
      }
    });

    _countEvents = countEvents?.call((count) {
      final newIdx = _idx.clamp(0, count);
      if (newIdx != _idx) {
        _setIdx(newIdx);
      } else {
        if (_prevCount != _idx) {
          _setIdx(newIdx);
        } else {
          _resortMap();
        }
      }

      _prevCount = count;

      setState(() {});
    });

    _setIdx(_idx);
  }

  (int, int, int) _clampTriplet((int, int, int) tuple) {
    return (
      tuple.$1.clamp(0, count - 1),
      tuple.$2,
      tuple.$3.clamp(0, count - 1),
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
          final value = _sortTags(e);
          if (value != null) {
            _values[e] = value;
          }
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
        final value = _sortTags(e);
        if (value != null) {
          _values[e] = value;
        }
      }
    }

    _idx = newIdx;
  }

  List<({String tag, bool pinned})>? _sortTags(int idx) {
    final postTags = getPost(idx)?.tags;
    if (postTags == null) {
      return null;
    }

    if (_pinnedTags.map.isEmpty) {
      return postTags.map((e) => (tag: e, pinned: false)).toList();
    }

    final postTags_ = postTags.toList();
    final pinnedTags = <String>[];
    postTags_.removeWhere((e) {
      if (_pinnedTags.map.containsKey(e)) {
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
      final value = _sortTags(e);
      if (value != null) {
        _values[e] = value;
      }
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
    // super.key,
    this.post,
    required this.animation,
    required this.child,
  });

  final PostImpl? post;

  final Animation<double> animation;

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
      clipRrect = Hero(tag: (post!.uniqueKey(), "tags"), child: clipRrect);
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) =>
          Opacity(opacity: animation.value, child: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 25 + 16),
          child: Padding(padding: EdgeInsets.zero, child: clipRrect),
        ),
      ),
    );
  }
}

class _TagsRowSingle extends StatefulWidget {
  const _TagsRowSingle({
    // super.key,
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
    return TagsRowChild(post: widget.post, tags: tags);
  }
}

class _TagsRowState extends State<_TagsRow> with _MultipleSortedTagArray {
  @override
  StreamSubscription<int> Function(void Function(int) f) get countEvents =>
      widget.source.backingStorage.watch;

  @override
  int get count => widget.source.count;

  @override
  PostImpl? getPost(int idx) => widget.source.forIdx(idx);

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
          final post = getPost(idx);
          final tags = getTags(idx);
          if (post == null || tags == null) {
            return const SizedBox.shrink();
          }

          return TagsRowChild(post: post, tags: tags);
        },
      ),
    );
  }
}

class TagsRowChild extends StatefulWidget {
  const TagsRowChild({super.key, required this.post, required this.tags});

  final PostImpl post;
  final List<({bool pinned, String tag})> tags;

  @override
  State<TagsRowChild> createState() => _TagsRowChildState();
}

class _TagsRowChildState extends State<TagsRowChild> {
  PostImpl get post => widget.post;
  List<({bool pinned, String tag})> get tags => widget.tags;

  final controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
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
                    controller.animateTo(
                      0,
                      duration: Durations.medium1,
                      curve: Easing.standardDecelerate,
                    );
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
            onPressed: () =>
                OnBooruTagPressed.pressOf(context, e.tag, post.booru),
          ),
        );
      },
    );
  }
}

class CardDialogContent extends StatefulWidget {
  const CardDialogContent({
    super.key,
    required this.source,
    required this.startingIdx,
    required this.post,
    required this.tryScrollTo,
  });

  final ResourceSource<int, PostImpl>? source;
  final int startingIdx;

  final void Function(int)? tryScrollTo;

  final PostImpl? post;

  @override
  State<CardDialogContent> createState() => _CardDialogContentState();
}

class _CardDialogContentState extends State<CardDialogContent>
    with ResourceSourceWatcher {
  late final controller = PageController(initialPage: widget.startingIdx);

  @override
  ResourceSource<int, PostImpl>? get source => widget.source;

  int _page = 0;

  @override
  void onResourceEvent() {
    if (widget.source == null) {
      return;
    }

    if (source?.count == 0) {
      Navigator.pop(context);
      return;
    }

    if (source?.count != 1) {
      _page = _page.clamp(0, source!.count - 1);
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _page = widget.startingIdx;

    controller.addListener(_listener);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void _listener() {
    final newPage = controller.page!.round();
    if (newPage != _page) {
      if (newPage >= widget.source!.count - 4 &&
          !source!.progress.inRefreshing &&
          source!.hasNext) {
        source!.next();
      }

      _page = newPage;
      widget.tryScrollTo?.call(newPage);
      setState(() {});
    }
  }

  Widget _itemBuilder(BuildContext context, PostImpl post, EdgeInsets padding) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.passthrough,
      children: [
        switch (post.type) {
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
            backgroundDecoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0),
            ),
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
            imageProvider: post.imageContent(),
          ),
        },
        Opacity(
          opacity: 0.65,
          child: Padding(
            padding:
                const EdgeInsets.all(12) +
                EdgeInsets.only(right: padding.right * 0.2),
            child: Align(
              alignment: Alignment.centerRight,
              child: FavoritePostButton(key: post.uniqueKey(), post: post),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.systemGestureInsetsOf(context);

    if (source == null) {
      if (widget.post == null) {
        return const SizedBox.shrink();
      }

      return _itemBuilder(context, widget.post!, padding);
    }

    final theme = Theme.of(context);

    return GestureDeadZones(
      right: true,
      left: true,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          PhotoViewGalleryIdx.builder(
            pageController: controller,
            backgroundDecoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0),
            ),
            onPageChanged: null,
            scrollDirection: Axis.vertical,
            itemCount: source!.count,
            loadingBuilder: (context, event, idx) {
              final theme = Theme.of(context);

              final t = widget.source!.forIdxUnsafe(idx).thumbnail();

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
            builder: (context, index) {
              final post = widget.source!.forIdxUnsafe(index);

              return switch (post.type) {
                PostContentType.none => PhotoViewGalleryPageOptions.customChild(
                  child: const SizedBox.shrink(),
                ),
                PostContentType.video =>
                  PhotoViewGalleryPageOptions.customChild(
                    child: Material(
                      child: _ExpandedVideo(
                        post: post,
                        child: PhotoGalleryPageVideo(
                          url: post.videoUrl(),
                          networkThumb: post.thumbnail(),
                          localVideo: false,
                        ),
                      ),
                    ),
                  ),
                PostContentType.gif ||
                PostContentType.image => PhotoViewGalleryPageOptions(
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: post.uniqueKey(),
                  ),
                  maxScale: PhotoViewComputedScale.contained * 1.8,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  filterQuality: FilterQuality.high,

                  imageProvider: post.imageContent(),
                ),
              };
            },
          ),
          Builder(
            builder: (context) {
              final post = widget.source?.forIdxUnsafe(_page);
              if (post == null) {
                return const SizedBox.shrink();
              }

              return Opacity(
                opacity: 0.65,
                child: Padding(
                  padding:
                      const EdgeInsets.all(12) +
                      EdgeInsets.only(right: padding.right * 0.2),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FavoritePostButton(
                      key: post.uniqueKey(),
                      post: post,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
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
  final videoControls = PlayerWidgetController();
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
      child: PlayerWidgetControllerNotifier(
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

class DownloadButton extends StatefulWidget {
  const DownloadButton({
    super.key,
    required this.post,
    this.secondVariant = false,
  });

  final PostImpl post;

  final bool secondVariant;

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> with DownloadManager {
  late final StreamSubscription<void> events;
  DownloadHandle? status;

  @override
  void initState() {
    super.initState();

    events = storage.watch((_) {
      setState(() {
        status = statusFor(widget.post.fileDownloadUrl());
      });
    }, true);
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
      DownloadStatus.onHold || null => const Icon(Icons.download_rounded),
      DownloadStatus.failed => const Icon(Icons.file_download_off_rounded),
      DownloadStatus.inProgress => const Icon(Icons.downloading_rounded),
    };

    return GestureDetector(
      onTap: downloadStatus == DownloadStatus.inProgress
          ? () {
              status?.cancel();
            }
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            onPressed:
                downloadStatus == DownloadStatus.onHold ||
                    downloadStatus == DownloadStatus.inProgress
                ? null
                : () {
                    if (downloadStatus == DownloadStatus.failed) {
                      restartAll([status!]);
                    } else {
                      widget.post.download();
                      WrapperSelectionAnimation.tryPlayOf(context);
                    }
                  },
            style: widget.secondVariant
                ? ButtonStyle(
                    foregroundColor: WidgetStateProperty.fromMap({
                      WidgetState.disabled: theme.disabledColor,
                      WidgetState.any: theme.colorScheme.surface,
                    }),
                    backgroundColor: WidgetStateProperty.fromMap({
                      WidgetState.disabled:
                          theme.colorScheme.surfaceContainerHigh,
                      WidgetState.any: theme.colorScheme.onSurfaceVariant,
                    }),
                  )
                : ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      downloadStatus == DownloadStatus.inProgress ||
                              downloadStatus == DownloadStatus.onHold
                          ? const CircleBorder()
                          : const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                    ),
                    foregroundColor: WidgetStateProperty.fromMap({
                      WidgetState.disabled: theme.disabledColor,
                      WidgetState.any: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.9),
                    }),
                    backgroundColor: WidgetStateProperty.fromMap({
                      WidgetState.disabled: theme
                          .colorScheme
                          .surfaceContainerHigh
                          .withValues(alpha: 0.8),
                      WidgetState.any: theme.colorScheme.surfaceContainer
                          .withValues(alpha: 0.8),
                    }),
                  ),
            icon: icon,
          ),
          if (status != null && downloadStatus == DownloadStatus.inProgress)
            _Progress(handle: status!),
        ],
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
      child: CircularProgressIndicator(strokeWidth: 2, value: progress),
    );
  }
}

class FavoritePostButton extends StatefulWidget {
  const FavoritePostButton({
    super.key,
    required this.post,
    this.withBackground = true,
    this.heroKey,
    this.backgroundAlpha = 0.4,
  });

  final PostImpl post;
  final bool withBackground;

  final double backgroundAlpha;
  final Object? heroKey;

  @override
  State<FavoritePostButton> createState() => _FavoritePostButtonState();
}

class _FavoritePostButtonState extends State<FavoritePostButton>
    with SingleTickerProviderStateMixin, FavoritePostSourceService {
  late final AnimationController controller;
  late final StreamSubscription<void> events;

  bool favorite = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);

    favorite = cache.isFavorite(widget.post.id, widget.post.booru);

    events = cache.streamSingle(widget.post.id, widget.post.booru).listen((
      newFavorite,
    ) {
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

    Widget child = TweenAnimationBuilder(
      curve: Easing.linear,
      tween: ColorTween(
        end: favorite ? Colors.pink : theme.colorScheme.surfaceContainer,
      ),
      duration: Durations.short3,
      builder: (context, value, child) => IconButton(
        style: widget.withBackground
            ? ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(value),
                backgroundColor: WidgetStatePropertyAll(
                  theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: widget.backgroundAlpha,
                  ),
                ),
              )
            : null,
        onPressed: () => addRemove([widget.post]),
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

    if (widget.heroKey != null) {
      child = Hero(tag: widget.heroKey!, child: child);
    }

    return child;
  }
}

class VideoOrGifIcon extends StatelessWidget {
  const VideoOrGifIcon({
    super.key,
    required this.type,
    required this.uniqueKey,
  });

  final Key uniqueKey;

  final PostContentType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final icon = switch (type) {
      PostContentType.none || PostContentType.image => null,
      PostContentType.video => Icons.play_arrow_rounded,
      PostContentType.gif => Icons.gif_rounded,
    };

    if (icon == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.secondary.withValues(alpha: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Hero(
          tag: (uniqueKey, "videoIcon"),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSecondary.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

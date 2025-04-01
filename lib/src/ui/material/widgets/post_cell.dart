// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/other/settings/radio_dialog.dart";
import "package:azari/src/ui/material/widgets/gesture_dead_zones.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/grid_cell/contentable.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_skeleton.dart";
import "package:azari/src/ui/material/widgets/image_view/video/photo_gallery_page_video.dart";
import "package:azari/src/ui/material/widgets/post_info.dart";
import "package:azari/src/ui/material/widgets/post_info_simple.dart";
import "package:azari/src/ui/material/widgets/shell/parts/sticker_widget.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:azari/src/ui/material/widgets/shimmer_loading_indicator.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photo_view/photo_view.dart";

class PostCell extends StatefulWidget {
  const PostCell({
    required super.key,
    required this.post,
    required this.wrapSelection,
  });

  final PostImpl post;

  final Widget Function(Widget child) wrapSelection;

  static Future<void> openMaximizedImage(
    BuildContext context,
    PostImpl post,
    Contentable content,
  ) {
    return Navigator.of(context, rootNavigator: true).push<void>(
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
          return _ExpandedImage(
            post: post,
            content: content,
          );
        },
      ),
    );
  }

  @override
  State<PostCell> createState() => _CellWidgetState();
}

class CardAnimation extends StatefulWidget {
  const CardAnimation({
    super.key,
    required this.animation,
    required this.source,
    required this.currentIndex,
    required this.syncr,
  });

  final ResourceSource<int, PostImpl> source;

  final Sink<(int, double?)> syncr;

  final int currentIndex;

  final Animation<double> animation;

  @override
  State<CardAnimation> createState() => _CardAnimationState();
}

class _CardAnimationState extends State<CardAnimation> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      child: ReplaceAnimation(
        source: widget.source,
        synchronizeSnd: widget.syncr,
        addScale: true,
        currentIndex: widget.currentIndex,
        child: (context, idx) {
          final post = widget.source.forIdxUnsafe(idx);

          final thumbnail = post.thumbnail(context);

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (360 * (post.height / post.width)).clamp(0, 420),
            ),
            child: GestureDetector(
              onTap: () {
                final post = widget.source.forIdxUnsafe(idx);
                final content = post.content(context);

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
                      return CurrentIndexMetadataNotifier(
                        metadata: StaticContentIndexMetadata(content: content),
                        refreshTimes: 0,
                        child: _BigImageVideo(
                          post: post,
                          content: content,
                        ),
                      );
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
                    AnimatedBuilder(
                      animation: widget.animation,
                      builder: (context, child) => Opacity(
                        opacity: widget.animation.value,
                        child: child,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(15)),
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
                ],
              ),
            ),
          );
        },
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

class CardDialog extends StatefulWidget {
  const CardDialog({
    super.key,
    required this.animation,
    required this.idx,
    required this.source,
    required this.tryScrollTo,
  });

  final Animation<double> animation;

  final void Function(int) tryScrollTo;

  final int idx;
  final ResourceSource<int, PostImpl> source;

  @override
  State<CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<CardDialog> {
  Animation<double> get animation => widget.animation;

  int get idx => widget.idx;
  ResourceSource<int, PostImpl> get source => widget.source;
  late final StreamSubscription<(int, double?)> _indexEvents;
  int _oldIdx = 0;

  final syncr = StreamController<(int, double?)>.broadcast();

  @override
  void initState() {
    super.initState();

    _oldIdx = widget.idx;

    _indexEvents = syncr.stream.listen((e) {
      if (e.$1 != _oldIdx) {
        _oldIdx = e.$1;

        widget.tryScrollTo(_oldIdx);

        if (context.mounted && source.count > 1) {
          if (_oldIdx != 0) {
            precacheImage(
              source.forIdxUnsafe(_oldIdx - 1).thumbnail(null),
              // ignore: use_build_context_synchronously
              context,
            );
          }

          if (_oldIdx != source.count - 1) {
            precacheImage(
              source.forIdxUnsafe(_oldIdx + 1).thumbnail(null),
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
    final theme = Theme.of(context);

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  CardAnimation(
                    currentIndex: idx,
                    syncr: syncr.sink,
                    source: source,
                    animation: animation,
                  ),
                  _TagsRow(
                    idx: idx,
                    syncr: syncr,
                    animation: animation,
                    source: source,
                  ),
                  ClipRRect(
                    child: ReplaceAnimation(
                      source: source,
                      synchronizeRecv: syncr.stream,
                      currentIndex: idx,
                      type: ReplaceAnimationType.vertical,
                      child: (context, idx) {
                        final post = source.forIdxUnsafe(idx);

                        return Padding(
                          padding: EdgeInsets.zero,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              spacing: 8,
                              children: [
                                AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, child) => Opacity(
                                    opacity: animation.value,
                                    child: child,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      showModalBottomSheet<void>(
                                        context: context,
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
                                  ),
                                ),
                                Row(
                                  spacing: 8,
                                  children: [
                                    if (FavoritePostSourceService.available)
                                      AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, child) => Opacity(
                                          opacity: animation.value,
                                          child: child,
                                        ),
                                        child: StarsButton(
                                          addBackground: true,
                                          idBooru: (post.id, post.booru),
                                        ),
                                      ),
                                    if (DownloadManager.available &&
                                        LocalTagsService.available)
                                      AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, child) => Opacity(
                                          opacity: animation.value,
                                          child: child,
                                        ),
                                        child: DownloadButton(
                                          post: post,
                                          secondVariant: true,
                                        ),
                                      ),
                                    if (FavoritePostSourceService.available &&
                                        post is! FavoritePost)
                                      FavoritePostButton(
                                        heroKey: (
                                          post.uniqueKey(),
                                          "favoritePost"
                                        ),
                                        post: post,
                                        backgroundAlpha: 1,
                                      )
                                    else if (FavoritePostSourceService
                                        .available)
                                      AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, child) => Opacity(
                                          opacity: animation.value,
                                          child: child,
                                        ),
                                        child: FavoritePostButton(
                                          post: post,
                                          backgroundAlpha: 1,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
  StreamController<(int, double?)> get syncr;
  int get initIdx;
  int get count => source.count;

  PostImpl getPost(int idx) => source.forIdxUnsafe(idx);

  ResourceSource<int, PostImpl> get source;

  (Map<String, void>, int) _pinnedTags = ({}, 0);
  final Map<int, List<({String tag, bool pinned})>> _values = {};

  int _idx = 0;

  late final StreamSubscription<(int, double?)> _events;
  late final StreamSubscription<int> _countEvents;

  List<({String tag, bool pinned})> getTags(int idx) => _values[idx]!;

  @override
  void initState() {
    super.initState();

    _idx = initIdx;

    _events = syncr.stream.listen((e) {
      if (e.$1 != _idx) {
        _setIdx(e.$1);
      }
    });

    _countEvents = source.backingStorage.watch((_) {
      _setIdx(_idx);
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
    _events.cancel();
    _countEvents.cancel();

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

class _TagsRowState extends State<_TagsRow> with _MultipleSortedTagArray {
  @override
  ResourceSource<int, PostImpl> get source => widget.source;

  @override
  int get count => source.count;

  @override
  PostImpl getPost(int idx) => source.forIdxUnsafe(idx);

  @override
  int get initIdx => widget.idx;

  @override
  StreamController<(int, double?)> get syncr => widget.syncr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) => Opacity(
        opacity: widget.animation.value,
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 25 + 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _CurrentTagsHero(
              source: source,
              initIdx: initIdx,
              synchronizeRecv: syncr.stream,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ReplaceAnimation(
                      source: source,
                      synchronizeRecv: widget.syncr.stream,
                      currentIndex: widget.idx,
                      child: (context, idx) {
                        final post = source.forIdxUnsafe(idx);
                        final tags = getTags(idx);

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
                                onDoublePressed:
                                    e.pinned || !TagManagerService.available
                                        ? null
                                        : () {
                                            // controller.animateTo(
                                            //   0,
                                            //   duration: Durations.medium3,
                                            //   curve: Easing.standard,
                                            // );

                                            const TagManagerService()
                                                .pinned
                                                .add(e.tag);
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
                      },
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

class _CurrentTagsHero extends StatefulWidget {
  const _CurrentTagsHero({
    // super.key,
    required this.source,
    required this.synchronizeRecv,
    required this.initIdx,
    required this.child,
  });

  final ResourceSource<int, PostImpl> source;
  final Stream<(int, double?)> synchronizeRecv;

  final int initIdx;

  final Widget child;

  @override
  State<_CurrentTagsHero> createState() => __CurrentTagsHeroState();
}

class __CurrentTagsHeroState extends State<_CurrentTagsHero> {
  late final StreamSubscription<(int, double?)> events;

  late PostImpl post;

  @override
  void initState() {
    super.initState();

    post = widget.source.forIdxUnsafe(widget.initIdx);

    events = widget.synchronizeRecv.listen((e) {
      setState(() {
        post = widget.source.forIdxUnsafe(e.$1);
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
    return Hero(
      tag: (post.uniqueKey(), "tags"),
      child: widget.child,
    );
  }
}

class _CellWidgetState extends State<PostCell>
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
    final thumbnail = post.thumbnail(context);

    final animate = PlayAnimations.maybeOf(context) ?? false;

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
                    if (FavoritePostSourceService.available &&
                        widget.post is! FavoritePost)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: FavoritePostButton(
                          heroKey: (post.uniqueKey(), "favoritePost"),
                          post: post,
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

        // if (tags.isEmpty) {
        //   return card;
        // }

        return card;
      },
    );

    if (animate) {
      return child.animate(key: post.uniqueKey()).fadeIn();
    }

    return child;
  }
}

class _BigImageVideo extends StatelessWidget {
  const _BigImageVideo({
    super.key,
    required this.post,
    required this.content,
  });

  final PostImpl post;
  final Contentable content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = content is NetVideo
        ? Material(
            child: _ExpandedVideo(
              post: post,
              child: PhotoGalleryPageVideo(
                url: (content as NetVideo).uri,
                networkThumb: post.thumbnail(context),
                localVideo: false,
              ),
            ),
          )
        : PhotoView(
            heroAttributes: PhotoViewHeroAttributes(tag: post.uniqueKey()),
            maxScale: PhotoViewComputedScale.contained * 1.8,
            minScale: PhotoViewComputedScale.contained * 0.8,
            filterQuality: FilterQuality.high,
            loadingBuilder: (context, event) {
              final theme = Theme.of(context);

              // try {
              //   final p =
              //       switch (_container!.pageController.position.userScrollDirection) {
              //     ScrollDirection.idle => _container!.pageController.page?.round(),
              //     ScrollDirection.forward => _container!.pageController.page?.floor(),
              //     ScrollDirection.reverse => _container!.pageController.page?.ceil(),
              //   };

              //   cell = drawCell(p ?? currentPage);
              // } catch (_) {}

              final t = content.widgets.tryAsThumbnailable(context);
              if (t == null) {
                return const SizedBox.shrink();
              }

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
              // final theme = Theme.of(context);

              // final expectedBytes = event?.expectedTotalBytes;
              // final loadedBytes = event?.cumulativeBytesLoaded;
              // final value = loadedBytes != null && expectedBytes != null
              //     ? loadedBytes / expectedBytes
              //     : null;

              // return Center(
              //   child: CircularProgressIndicator(
              //     year2023: false,
              //     color: theme.colorScheme.onSurfaceVariant,
              //     backgroundColor:
              //         theme.colorScheme.surfaceContainer.withValues(alpha: 0.4),
              //     value: value,
              //   ),
              // );
            },
            backgroundDecoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0),
            ),
            imageProvider: content is NetImage
                ? (content as NetImage).provider
                : (content as NetGif).provider,
          );

    return child;
  }
}

class _ExpandedImage extends StatelessWidget {
  const _ExpandedImage({
    // super.key,
    required this.post,
    required this.content,
  });

  final PostImpl post;
  final Contentable content;

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
            child: PhotoGalleryPageVideo(
              url: (content as NetVideo).uri,
              networkThumb: post.thumbnail(context),
              localVideo: false,
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
          IconButtonTheme(
            data: IconButtonThemeData(style: buttonStyle),
            child: StarsButton(
              idBooru: (post.id, post.booru),
            ),
          ),
          if (FavoritePostSourceService.available)
            IconButtonTheme(
              data: IconButtonThemeData(style: buttonStyle),
              child: FavoritePostButton(
                post: post,
                withBackground: false,
              ),
            ),
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

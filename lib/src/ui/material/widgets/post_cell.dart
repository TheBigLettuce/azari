// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/platform/generated/platform_api.g.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/services/obj_impls/post_impl.dart";
import "package:azari/src/services/resource_source/resource_source.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/booru/booru_page.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/pages/other/settings/radio_dialog.dart";
import "package:azari/src/ui/material/widgets/gesture_dead_zones.dart";
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
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photo_view/photo_view.dart";

class PostCell extends StatefulWidget {
  const PostCell({
    required super.key,
    required this.post,
    required this.wrapSelection,
    required this.favoritePosts,
    required this.tagManager,
    required this.downloadManager,
    required this.settingsService,
    required this.localTags,
  });

  final PostImpl post;

  final FavoritePostSourceService? favoritePosts;
  final TagManagerService? tagManager;
  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;

  final SettingsService settingsService;

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
          final db = Services.of(context);

          return _ExpandedImage(
            post: post,
            content: content,
            videoSettings: db.get<VideoSettingsService>(),
            favoritePosts: db.get<FavoritePostSourceService>(),
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
    required this.favoritePosts,
    required this.animation,
    required this.source,
    required this.currentIndex,
    required this.syncr,
  });

  final FavoritePostSourceService? favoritePosts;

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
                PlatformApi().setWakelock(true);

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
                          videoSettings: Services.getOf<VideoSettingsService>(
                            context,
                          ),
                          favoritePosts: widget.favoritePosts,
                        ),
                      );
                    },
                  ),
                )
                    .then((_) {
                  PlatformApi().setWakelock(false);
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
                        child: const SizedBox.expand(
                          child: Center(
                            child: Icon(Icons.play_arrow_rounded),
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
    print("Commit fwd");
  }

  void commitBackward([double? overrideFrom]) {
    if (controller.isAnimating || controller.value > 0.8) {
      return;
    }

    controller.value = overrideFrom ?? 0.8;
    controller.animateTo(1, curve: Easing.emphasizedAccelerate).then((_) {
      controller.value = 0;
      setState(() {
        idx -= 1;
      });
    });
    print("Commit back");
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
                          commitForward(animValue?.roundToDouble());

                          return;
                        } else if (animValue != null &&
                            !animValue!.isNegative &&
                            animValue! >= 0.5) {
                          commitBackward(animValue?.roundToDouble());

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
                              ((animValue ?? 0) + (details.delta.dx * 0.017))
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
    required this.settingsService,
    required this.favoritePosts,
    required this.tagManager,
    required this.downloadManager,
    required this.localTags,
    required this.idx,
    required this.source,
  });

  final FavoritePostSourceService? favoritePosts;
  final TagManagerService? tagManager;
  final DownloadManager? downloadManager;
  final LocalTagsService? localTags;

  final SettingsService settingsService;

  final Animation<double> animation;

  final int idx;
  final ResourceSource<int, PostImpl> source;

  @override
  State<CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<CardDialog> {
  FavoritePostSourceService? get favoritePosts => widget.favoritePosts;
  TagManagerService? get tagManager => widget.tagManager;
  DownloadManager? get downloadManager => widget.downloadManager;
  LocalTagsService? get localTags => widget.localTags;

  SettingsService get settingsService => widget.settingsService;

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

        if (context.mounted && source.count > 1) {
          if (_oldIdx != 0) {
            precacheImage(
                source.forIdxUnsafe(_oldIdx - 1).thumbnail(null), context);
          }

          if (_oldIdx != source.count - 1) {
            precacheImage(
                source.forIdxUnsafe(_oldIdx + 1).thumbnail(null), context);
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    return Center(
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
                  favoritePosts: favoritePosts,
                  currentIndex: idx,
                  syncr: syncr.sink,
                  source: source,
                  animation: animation,
                ),
                _TagsRow(
                  tagManager: tagManager,
                  settingsService: settingsService,
                  idx: idx,
                  syncr: syncr,
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
                        padding: const EdgeInsets.only(bottom: 0),
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
                                            width:
                                                MediaQuery.sizeOf(sheetContext)
                                                    .width,
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
                                  AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, child) => Opacity(
                                      opacity: animation.value,
                                      child: child,
                                    ),
                                    child: StarsButton(
                                      favoritePosts: favoritePosts,
                                      addBackground: true,
                                      idBooru: (post.id, post.booru),
                                    ),
                                  ),
                                  if (downloadManager != null &&
                                      localTags != null)
                                    AnimatedBuilder(
                                      animation: animation,
                                      builder: (context, child) => Opacity(
                                        opacity: animation.value,
                                        child: child,
                                      ),
                                      child: DownloadButton(
                                        downloadManager: downloadManager!,
                                        post: post,
                                        secondVariant: true,
                                        localTags: localTags!,
                                        settingsService: settingsService,
                                      ),
                                    ),
                                  if (favoritePosts != null &&
                                      post is! FavoritePost)
                                    FavoritePostButton(
                                      heroKey: (
                                        post.uniqueKey(),
                                        "favoritePost"
                                      ),
                                      post: post,
                                      backgroundAlpha: 1,
                                      favoritePosts: favoritePosts!,
                                    )
                                  else
                                    AnimatedBuilder(
                                      animation: animation,
                                      builder: (context, child) => Opacity(
                                        opacity: animation.value,
                                        child: child,
                                      ),
                                      child: FavoritePostButton(
                                        post: post,
                                        backgroundAlpha: 1,
                                        favoritePosts: favoritePosts!,
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
    );
  }
}

// if (post is! FavoritePost &&
//     post.type == PostContentType.image)
//   Align(
//     alignment: Alignment.topRight,
//     child: Padding(
//       padding: const EdgeInsets.all(8),
//       child: IconButton(
//         style: ButtonStyle(
//           visualDensity: VisualDensity.compact,
//           foregroundColor: WidgetStatePropertyAll(
//             theme.colorScheme.surface
//                 .withValues(alpha: 0.9),
//           ),
//           backgroundColor: WidgetStatePropertyAll(
//             theme.colorScheme.onSurface
//                 .withValues(alpha: 0.8),
//           ),
//         ),
//         onPressed: () => PostCell.openMaximizedImage(
//           context,
//           post,
//           settings.sampleThumbnails
//               ? content
//               : post.content(context, true),
//         ),
//         icon: const Icon(Icons.open_in_full),
//       ),
//     ),
//   ),

class _TagsRow extends StatefulWidget {
  const _TagsRow({
    super.key,
    required this.tagManager,
    required this.settingsService,
    required this.idx,
    required this.syncr,
    required this.source,
  });

  final TagManagerService? tagManager;

  final SettingsService settingsService;

  final int idx;

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

    return Padding(
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
                                  e.pinned || widget.tagManager == null
                                      ? null
                                      : () {
                                          // controller.animateTo(
                                          //   0,
                                          //   duration: Durations.medium3,
                                          //   curve: Easing.standard,
                                          // );

                                          widget.tagManager!.pinned.add(e.tag);
                                        },
                              onLongPressed: post is FavoritePost
                                  ? null
                                  : () {
                                      context.openSafeModeDialog(
                                          widget.settingsService, (safeMode) {
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
    );
  }
}

class _CurrentTagsHero extends StatefulWidget {
  const _CurrentTagsHero({
    super.key,
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
                          heroKey: (post.uniqueKey(), "favoritePost"),
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
              height: 25,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Hero(
                  tag: (post.uniqueKey(), "tags"),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: null,
                    ),
                    child: ListView.builder(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.antiAlias,
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final e = tags[index];

                        return Center(
                          child: OutlinedTagChip(
                            tag: e.tag,
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
                          ),
                        );
                      },
                    ),
                  ),
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

class _BigImageVideo extends StatelessWidget {
  const _BigImageVideo({
    super.key,
    required this.post,
    required this.content,
    required this.videoSettings,
    required this.favoritePosts,
  });

  final PostImpl post;
  final Contentable content;

  final VideoSettingsService? videoSettings;
  final FavoritePostSourceService? favoritePosts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = content is NetVideo
        ? Material(
            child: _ExpandedVideo(
              post: post,
              videoSettings: videoSettings,
              child: PhotoGalleryPageVideo(
                url: (content as NetVideo).uri,
                networkThumb: post.thumbnail(context),
                localVideo: false,
                videoSettings: videoSettings,
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
                      year2023: false,
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
    required this.videoSettings,
    required this.favoritePosts,
  });

  final PostImpl post;
  final Contentable content;

  final VideoSettingsService? videoSettings;
  final FavoritePostSourceService? favoritePosts;

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
          IconButtonTheme(
            data: IconButtonThemeData(style: buttonStyle),
            child: StarsButton(
              favoritePosts: favoritePosts,
              idBooru: (post.id, post.booru),
            ),
          ),
          if (favoritePosts != null)
            IconButtonTheme(
              data: IconButtonThemeData(style: buttonStyle),
              child: FavoritePostButton(
                post: post,
                favoritePosts: favoritePosts!,
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

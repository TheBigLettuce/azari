// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/services.dart";
import "package:azari/src/platform/platform_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/contentable.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/sticker.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/image_view/image_view_fab.dart";
import "package:azari/src/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/widgets/image_view/video/photo_gallery_page_video.dart";
import "package:azari/src/widgets/loading_error_widget.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:photo_view/photo_view.dart";
import "package:photo_view/photo_view_gallery.dart";

class _StateContainer {
  _StateContainer({
    required this.context,
    required this.preloadNextPictures,
    required this.flipShowAppBar,
    required int initialPage,
    required this.playAnimationLeft,
    required this.playAnimationRight,
  }) : pageController = PageController(initialPage: initialPage);

  final bool preloadNextPictures;

  final PageController pageController;

  final VoidCallback playAnimationLeft;
  final VoidCallback playAnimationRight;
  final VoidCallback flipShowAppBar;

  final bodyKey = GlobalKey();

  final BuildContext context;

  void init(Stream<int> countEvents) {}

  void dispose() {
    pageController.dispose();
  }
}

class DefaultStateController extends ImageViewStateController {
  DefaultStateController({
    required this.getContent,
    required int count,
    required this.videoSettingsService,
    Stream<int>? countEvents,
    this.scrollUntill,
    this.preloadNextPictures = false,
    this.ignoreLoadingBuilder = false,
    this.pageChange,
    this.statistics,
    this.download,
    this.onNearEnd,
    this.tags,
    this.watchTags,
    this.wrapNotifiers,
  }) : _count = count {
    countEventsController = StreamController.broadcast();

    if (countEvents == null) {
      this.countEvents = countEventsController.stream;
    } else {
      this.countEvents = countEventsController.stream;
      upstreamCountEvents = countEvents.listen((count) {
        countEventsController.add(count);
      });
    }

    _updates = this.countEvents.listen((newCount) {
      final shiftCurrentIndex = newCount - count;

      _count = newCount;
      if (onNearEnd != null) {
        return;
      }

      final prevIndex = currentIndex;
      currentIndex = (prevIndex +
              (shiftCurrentIndex.isNegative || prevIndex == 0
                  ? 0
                  : shiftCurrentIndex))
          .clamp(0, count - 1);

      if (currentIndex != prevIndex && prevIndex != 0) {
        _indexStreamController.add(currentIndex);

        _container?.pageController.jumpToPage(currentIndex);
      } else {
        if (count != newCount) {
          statistics?.viewed();
        }

        loadCells(currentIndex, count);
      }
    });
  }

  final bool preloadNextPictures;
  final bool ignoreLoadingBuilder;

  final ImageViewStatistics? statistics;

  final ContentIdxCallback? scrollUntill;
  final ContentIdxCallback? download;

  final WatchTagsCallback? watchTags;
  final NotifierWrapper? wrapNotifiers;

  // final VoidCallback? onRightSwitchPageEnd;
  // final VoidCallback? onLeftSwitchPageEnd;

  final ContentGetter getContent;
  final List<ImageTag> Function(ContentWidgets)? tags;
  final Future<int> Function()? onNearEnd;

  final VideoSettingsService? videoSettingsService;

  final void Function(DefaultStateController state)? pageChange;
  @override
  late final Stream<int> countEvents;

  late final StreamController<int> countEventsController;
  StreamSubscription<int>? upstreamCountEvents;

  _StateContainer? _container;

  int _count;

  @override
  int get count => _count;
  set count(int c) {
    _count = c;

    countEventsController.add(c);
  }

  @override
  int currentIndex = 0;

  final _indexStreamController = StreamController<int>.broadcast();

  @override
  Stream<int> get indexEvents => _indexStreamController.stream;

  late final StreamSubscription<void> _updates;

  (Contentable, int)? _currentCell;
  // ignore: use_late_for_private_fields_and_variables
  (Contentable, int)? _previousCell;
  (Contentable, int)? _nextCell;

  int refreshTries = 0;
  bool refreshing = false;

  (Contentable, int) currentCell() => _currentCell!;
  (ContentWidgets, int) currentContentWidgets() =>
      (_currentCell!.$1.widgets, _currentCell!.$2);

  @override
  void refreshImage() {
    loadCells(currentIndex, count);

    final c = drawCell(currentIndex, true);
    if (c is NetImage) {
      c.provider.evict();
    } else if (c is NetGif) {
      c.provider.evict();
    }
  }

  void dispose() {
    _updates.cancel();
    _indexStreamController.close();
    upstreamCountEvents?.cancel();
    countEventsController.close();
  }

  @override
  void bind(
    BuildContext context, {
    required int startingIndex,
    required VoidCallback playAnimationLeft,
    required VoidCallback playAnimationRight,
    required VoidCallback flipShowAppBar,
  }) {
    // if (startingIndex != 0) {
    currentIndex = startingIndex;
    _indexStreamController.add(currentIndex);
    // }

    _container = _StateContainer(
      initialPage: startingIndex,
      playAnimationLeft: playAnimationLeft,
      playAnimationRight: playAnimationRight,
      preloadNextPictures: preloadNextPictures,
      flipShowAppBar: flipShowAppBar,
      context: context,
    );

    loadCells(currentIndex, count);

    statistics?.viewed();
  }

  @override
  void unbind() {
    _container?.dispose();
  }

  @override
  void seekTo(int i) {
    _container?.pageController.jumpToPage(i);
  }

  void loadCells(int i, int maxCells) {
    _currentCell = (getContent(i)!, i);

    if (i != 0 && !i.isNegative) {
      final c2 = getContent(i - 1);

      if (c2 != null) {
        _previousCell = (c2, i - 1);

        final content = c2;
        if (preloadNextPictures && content is NetImage) {
          WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
            final context = _container?.context;
            if (context == null || !context.mounted) {
              return;
            }

            precacheImage(content.provider, context);
            final thumb = content.widgets.tryAsThumbnailable(context);
            if (thumb != null) {
              precacheImage(thumb, context);
            }
          });
        }
      }
    }

    if (maxCells != i + 1) {
      final c3 = getContent(i + 1);

      if (c3 != null) {
        _nextCell = (c3, i + 1);

        final content = c3;
        if (preloadNextPictures && content is NetImage) {
          WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
            final context = _container?.context;
            if (context == null || !context.mounted) {
              return;
            }

            precacheImage(content.provider, context);
            final thumb = content.widgets.tryAsThumbnailable(context);
            if (thumb != null) {
              precacheImage(thumb, context);
            }
          });
        }
      }
    }
  }

  Widget loadingBuilder(
    BuildContext context,
    ImageChunkEvent? event,
    int index,
    int currentPage,
    Contentable Function(int) drawCell,
  ) {
    final theme = Theme.of(context);

    final cell = drawCell(index);
    // try {
    //   final p =
    //       switch (_container!.pageController.position.userScrollDirection) {
    //     ScrollDirection.idle => _container!.pageController.page?.round(),
    //     ScrollDirection.forward => _container!.pageController.page?.floor(),
    //     ScrollDirection.reverse => _container!.pageController.page?.ceil(),
    //   };

    //   cell = drawCell(p ?? currentPage);
    // } catch (_) {}

    final t = cell.widgets.tryAsThumbnailable(context);
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
            backgroundColor:
                theme.colorScheme.surfaceContainer.withValues(alpha: 0.4),
            value: value ?? 0,
          ),
        ),
      ],
    );
  }

  @override
  Widget injectMetadataProvider(Widget child) {
    final ret = ImageViewTagsProvider(
      currentPage: indexEvents,
      currentCell: currentContentWidgets,
      tags: tags,
      watchTags: watchTags,
      child: _CurrentIndexMetadataHolder(
        getContent: getContent,
        currentIndex: currentIndex,
        indexEvents: indexEvents,
        currentCount: _count,
        countEvents: countEvents,
        wrapNotifiers: wrapNotifiers,
        child: child,
      ),
    );

    if (wrapNotifiers == null) {
      return ret;
    }

    return wrapNotifiers!(ret);
  }

  void _onPageChanged(int index) {
    statistics?.viewed();
    statistics?.swiped();

    refreshTries = 0;

    currentIndex = index;
    _indexStreamController.add(currentIndex);

    pageChange?.call(this);
    _loadNext(index);

    scrollUntill?.call(index);

    loadCells(index, count);

    final c = drawCell(index);

    PlatformApi().window.setTitle(c.widgets.alias(false));
  }

  @override
  Widget buildBody(BuildContext context) {
    assert(_container != null);

    return ImageViewBody(
      key: _container!.bodyKey,
      onPressedLeft: null,
      onPressedRight: null,
      onPageChanged: _onPageChanged,
      onLongPress: _onLongPress,
      pageController: _container!.pageController,
      countEvents: countEvents,
      loadingBuilder: (context, event, index) => loadingBuilder(
        context,
        event,
        index,
        currentIndex,
        drawCell,
      ),
      itemCount: count,
      onTap: _container!.flipShowAppBar,
      builder: galleryBuilder,
    );
  }

  Contentable drawCell(int i, [bool currentCellOnly = false]) {
    if (currentCellOnly) {
      return _currentCell!.$1;
    }

    if (_currentCell != null && _currentCell!.$2 == i) {
      return _currentCell!.$1;
    } else if (_nextCell != null && _nextCell!.$2 == i) {
      return _nextCell!.$1;
    } else {
      return _previousCell!.$1;
    }
  }

  PhotoViewGalleryPageOptions galleryBuilder(BuildContext context, int i) {
    final cell = drawCell(i);
    final content = cell;
    final key = cell.widgets.uniqueKey();

    return switch (content) {
      NetGif() => _makeNetImage(key, content.provider),
      NetImage() => _makeNetImage(key, content.provider),
      NetVideo() => _makeVideo(
          context,
          key,
          content.uri,
          cell.widgets.tryAsThumbnailable(context),
        ),
      EmptyContent() =>
        PhotoViewGalleryPageOptions.customChild(child: const SizedBox.shrink())
    };
  }

  PhotoViewGalleryPageOptions _makeVideo(
    BuildContext context,
    Key key,
    String uri,
    ImageProvider? networkThumb,
  ) =>
      PhotoViewGalleryPageOptions.customChild(
        disableGestures: true,
        tightMode: true,
        child: PhotoGalleryPageVideo(
          key: key,
          url: uri,
          networkThumb: networkThumb,
          localVideo: false,
          videoSettings: videoSettingsService,
        ),
      );

  PhotoViewGalleryPageOptions _makeNetImage(Key key, ImageProvider provider) {
    final options = PhotoViewGalleryPageOptions(
      key: ValueKey((key, refreshTries)),
      minScale: PhotoViewComputedScale.contained * 0.8,
      maxScale: PhotoViewComputedScale.covered * 1.8,
      initialScale: PhotoViewComputedScale.contained,
      filterQuality: FilterQuality.high,
      imageProvider: provider,
      errorBuilder: (context, error, stackTrace) {
        return LoadingErrorWidget(
          error: error.toString(),
          short: false,
          refresh: () {
            ReloadImageNotifier.of(context);
          },
        );
      },
    );

    return options;
  }

  void _onLongPress() {
    if (download == null) {
      return;
    }

    HapticFeedback.vibrate();
    download!(currentIndex);
  }

  void _loadNext(int index) {
    if (onNearEnd == null) {
      return;
    }

    if (index >= count - 3 && !refreshing) {
      refreshing = true;

      onNearEnd!().then((i) {
        count = i;
      }).whenComplete(() {
        refreshing = false;
      });
    }
  }
}

class _CurrentIndexMetadataHolder extends StatefulWidget {
  const _CurrentIndexMetadataHolder({
    // super.key,
    required this.getContent,
    required this.currentIndex,
    required this.indexEvents,
    required this.wrapNotifiers,
    required this.countEvents,
    required this.currentCount,
    required this.child,
  });

  final ContentGetter getContent;

  final int currentIndex;
  final int currentCount;

  final Stream<int> indexEvents;
  final Stream<int> countEvents;

  final NotifierWrapper? wrapNotifiers;

  final Widget child;

  @override
  State<_CurrentIndexMetadataHolder> createState() =>
      __CurrentIndexMetadataHolderState();
}

class __CurrentIndexMetadataHolderState
    extends State<_CurrentIndexMetadataHolder> {
  late final StreamSubscription<int> indexEvents;
  late final StreamSubscription<int> countEvents;

  late _ContentToMetadata currentMetadata;
  int refreshCounts = 0;

  @override
  void initState() {
    super.initState();

    indexEvents = widget.indexEvents.listen((newIndex) {
      currentMetadata = _ContentToMetadata(
        indexEvents: widget.indexEvents,
        countEvents: widget.countEvents,
        content: widget.getContent(newIndex)!,
        getContent: widget.getContent,
        wrapNotifiers: widget.wrapNotifiers,
        index: newIndex,
        count: currentMetadata.count,
      );

      refreshCounts += 1;

      setState(() {});
    });

    countEvents = widget.countEvents.listen((newCount) {
      currentMetadata = _ContentToMetadata(
        indexEvents: widget.indexEvents,
        countEvents: widget.countEvents,
        content: widget.getContent(currentMetadata.index)!,
        getContent: widget.getContent,
        wrapNotifiers: widget.wrapNotifiers,
        index: currentMetadata.index,
        count: newCount,
      );

      refreshCounts += 1;

      setState(() {});
    });

    currentMetadata = _ContentToMetadata(
      indexEvents: widget.indexEvents,
      countEvents: widget.countEvents,
      content: widget.getContent(widget.currentIndex)!,
      getContent: widget.getContent,
      wrapNotifiers: widget.wrapNotifiers,
      count: widget.currentCount,
      index: widget.currentIndex,
    );
  }

  @override
  void dispose() {
    indexEvents.cancel();
    countEvents.cancel();

    super.dispose();
  }

  ImageProvider? _getThumbnail(int i) =>
      widget.getContent(i)?.widgets.tryAsThumbnailable(null);

  @override
  Widget build(BuildContext context) {
    return ThumbnailsNotifier(
      provider: _getThumbnail,
      child: CurrentIndexMetadataNotifier(
        metadata: currentMetadata,
        refreshTimes: refreshCounts,
        child: widget.child,
      ),
    );
  }
}

class _ContentToMetadata implements CurrentIndexMetadata {
  const _ContentToMetadata({
    required this.content,
    required this.index,
    required this.getContent,
    required this.countEvents,
    required this.indexEvents,
    required this.wrapNotifiers,
    required this.count,
  });

  final NotifierWrapper? wrapNotifiers;
  final ContentGetter getContent;
  final Stream<int> indexEvents;
  final Stream<int> countEvents;

  @override
  final int count;

  @override
  bool get isVideo => content is NetVideo;

  @override
  Key get uniqueKey => content.widgets.uniqueKey();

  @override
  final int index;
  final Contentable content;

  @override
  List<ImageViewAction> actions(BuildContext context) =>
      content.widgets.tryAsActionable(context);

  @override
  List<NavigationAction> appBarButtons(BuildContext context) =>
      content.widgets.tryAsAppBarButtonable(context);

  @override
  Widget? openMenuButton(BuildContext context) {
    return ImageViewFab(
      openBottomSheet: (context) {
        return showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) {
            final child = ExitOnPressRoute(
              exit: () {
                Navigator.of(sheetContext).pop();
                ExitOnPressRoute.exitOf(context);
              },
              child: PauseVideoNotifierHolder(
                state: PauseVideoNotifier.stateOf(context),
                child: ImageTagsNotifier(
                  tags: ImageTagsNotifier.of(context),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
                    ),
                    child: SizedBox(
                      width: MediaQuery.sizeOf(sheetContext).width,
                      child: _CellContent(
                        firstContent: (CurrentIndexMetadata.of(context)
                                as _ContentToMetadata)
                            .content,
                        firstIndex: index,
                        getContent: getContent,
                        indexEvents: indexEvents,
                        countEvents: countEvents,
                      ),
                    ),
                  ),
                ),
              ),
            );

            if (wrapNotifiers != null) {
              return wrapNotifiers!(child);
            }

            return child;
          },
        );
      },
    );
  }

  @override
  List<Sticker> stickers(BuildContext context) =>
      content.widgets.tryAsStickerable(context, true);
}

class _CellContent extends StatefulWidget {
  const _CellContent({
    // super.key,
    required this.indexEvents,
    required this.getContent,
    required this.countEvents,
    required this.firstContent,
    required this.firstIndex,
  });

  final Contentable firstContent;
  final int firstIndex;
  final Stream<int> indexEvents;
  final Stream<int> countEvents;
  final ContentGetter getContent;

  @override
  State<_CellContent> createState() => __CellContentState();
}

class __CellContentState extends State<_CellContent> {
  late final StreamSubscription<int> countEvents;
  late final StreamSubscription<int> indexEvents;

  late Contentable content;

  late int currentIndex;

  int refreshes = 0;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.firstIndex;

    content = widget.firstContent;

    indexEvents = widget.indexEvents.listen((newContent) {
      setState(() {
        content = widget.getContent(newContent)!;
        currentIndex = newContent;
      });
    });

    countEvents = widget.countEvents.listen((newCount) {
      final newContent = widget.getContent(currentIndex);
      if (newContent == null) {
        return;
      }

      setState(() {
        content = newContent;
        refreshes += 1;
      });
    });
  }

  @override
  void dispose() {
    countEvents.cancel();
    indexEvents.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(refreshes),
      child: content.widgets.tryAsInfoable(context) ?? const SizedBox.shrink(),
    );
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photo_view/photo_view_gallery.dart";

class _StateContainer {
  _StateContainer({
    required this.context,
    // required this.preloadNextPictures,
    required this.flipShowAppBar,
    required int initialPage,
    required this.playAnimationLeft,
    required this.playAnimationRight,
  }) : pageController = PageController(initialPage: initialPage);

  // final bool preloadNextPictures;

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

// {
//   countEventsController = StreamController.broadcast();

//   // if (countEvents == null) {
//   //   this.countEvents = countEventsController.stream;
//   // } else {
//   countEvents = countEventsController.stream;
//   upstreamCountEvents = countEvents.listen((count) {
//     countEventsController.add(count);
//   });
//   // }

//   _updates = countEvents.listen((newCount) {
//     final shiftCurrentIndex = newCount - count;

//     _count = newCount;
//     if (onNearEnd != null) {
//       return;
//     }

//     final prevIndex = currentIndex;
//     currentIndex = (prevIndex +
//             (shiftCurrentIndex.isNegative || prevIndex == 0
//                 ? 0
//                 : shiftCurrentIndex))
//         .clamp(0, count - 1);

//     if (currentIndex != prevIndex && prevIndex != 0) {
//       _indexStreamController.add(currentIndex);

//       _container?.pageController.jumpToPage(currentIndex);
//     } else {
//       if (count != newCount) {
//         statistics?.viewed();
//       }

//       loadCells(currentIndex, count);
//     }
//   });
// }

abstract class DefaultImageViewLoader<T extends ImageViewWidgets>
    implements ImageViewLoader {
  DefaultImageViewLoader({
    required this.precacheThumbs,
  }) {
    initCountEvents(_countEventsController.sink);
  }

  ResourceSource<dynamic, T> get resource;

  final bool precacheThumbs;

  final _indexStreamController = StreamController<int>.broadcast();
  final _countEventsController = StreamController<int>.broadcast();

  int refreshTries = 0;

  int _index = 0;

  @override
  int get count => resource.count;

  @override
  int get index => _index;
  set index(int i) {
    _index = 0;
    _indexStreamController.add(i);
  }

  @override
  Stream<int> get indexEvents => _indexStreamController.stream;

  @override
  Stream<int> get countEvents => _countEventsController.stream;

  PhotoViewGalleryPageOptions? drawOptions(int i);

  @override
  List<ImageTag> tagsFor(int i);

  @override
  Stream<void> tagsEventsFor(int i);

  void initCountEvents(Sink<int> sink);

  @override
  ImageViewWidgets? get(int i) => resource.forIdx(i);

  void tryPrecacheThumb(BuildContext context, ImageViewWidgets widgets) {
    if (precacheThumbs) {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        if (!context.mounted) {
          return;
        }

        final thumb = widgets.thumbnail();
        if (thumb != null) {
          precacheImage(thumb, context);
        }
      });
    }
  }

  // void loadCells(BuildContext context, int i) {
  //   _currentCell = (resource.forIdxUnsafe(i), i);

  //   if (i != 0 && !i.isNegative) {
  //     final c2 = resource.forIdx(i - 1);

  //     if (c2 != null) {
  //       _previousCell = (c2, i - 1);

  //       tryPrecacheThumb(context, c2);
  //     }
  //   }

  //   if (count != i + 1) {
  //     final c3 = resource.forIdx(i + 1);

  //     if (c3 != null) {
  //       _nextCell = (c3, i + 1);

  //       tryPrecacheThumb(context, c3);
  //     }
  //   }
  // }

  void loadNext(int index) {
    if (!resource.hasNext || resource.progress.inRefreshing) {
      return;
    }

    resource.next();
  }

  @mustCallSuper
  void dispose() {
    _countEventsController.close();
    _indexStreamController.close();
  }
}

//   static List<ImageTag> imageViewTags(
//     ContentWidgets c,
//     TagManagerService tagManager,
//   ) =>
//       (c as PostBase)
//           .tags
//           .map(
//             (e) => ImageTag(
//               e,
//               favorite: tagManager.pinned.exists(e),
//               excluded: tagManager.excluded.exists(e),
//             ),
//           )
//           .toList();

//   static StreamSubscription<List<ImageTag>> watchTags(
//     ContentWidgets c,
//     void Function(List<ImageTag> l) f,
//     BooruTagging<Pinned> pinnedTags,
//   ) =>
//       pinnedTags.watchImage((c as PostBase).tags, f);
// }

class DefaultStateController extends ImageViewStateController {
  DefaultStateController({
    required this.loader,
    // this.scrollUntill,
    // this.preloadNextPictures = false,
    this.ignoreLoadingBuilder = false,
    this.pageChange,
    this.statistics,
    this.download,
    // this.watchTags,
    this.wrapNotifiers,
  });

  // final bool preloadNextPictures;
  final bool ignoreLoadingBuilder;

  final ImageViewStatistics? statistics;

  // final ContentIdxCallback? scrollUntill;
  final ContentIdxCallback? download;

  // final WatchTagsCallback? watchTags;
  final NotifierWrapper? wrapNotifiers;

  @override
  final DefaultImageViewLoader loader;

  final void Function(DefaultStateController state)? pageChange;

  _StateContainer? _container;

  void dispose() {
    _container?.dispose();
    _container = null;
  }

  @override
  void bind(
    BuildContext context, {
    required int startingIndex,
    required VoidCallback playAnimationLeft,
    required VoidCallback playAnimationRight,
    required VoidCallback flipShowAppBar,
  }) {
    loader.index = startingIndex;

    _container = _StateContainer(
      initialPage: startingIndex,
      playAnimationLeft: playAnimationLeft,
      playAnimationRight: playAnimationRight,
      // preloadNextPictures: preloadNextPictures,
      flipShowAppBar: flipShowAppBar,
      context: context,
    );

    // loader.loadCells(context, startingIndex);

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

  Widget loadingBuilder(
    BuildContext context,
    ImageChunkEvent? event,
    int index,
  ) {
    final theme = Theme.of(context);

    final cell = loader.get(index);

    final t = cell?.thumbnail();
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
            backgroundColor:
                theme.colorScheme.surfaceContainer.withValues(alpha: 0.4),
            value: value ?? 0,
          ),
        ),
      ],
    );
  }

  // @override
  // Widget injectMetadataProvider(Widget child) {
  //   final ret = ImageViewTagsProvider(
  //     currentPage: indexEvents,
  //     countEvents: countEvents,
  //     currentCell: currentContentWidgets,
  //     tags: tags,
  //     watchTags: watchTags,
  //     child: ContentIndexMetadataHolder(
  //       getContent: getContent,
  //       currentIndex: currentIndex,
  //       indexEvents: indexEvents,
  //       currentCount: _count,
  //       countEvents: countEvents,
  //       wrapNotifiers: wrapNotifiers,
  //       child: child,
  //     ),
  //   );

  //   if (wrapNotifiers == null) {
  //     return ret;
  //   }

  //   return wrapNotifiers!(ret);
  // }

  void _onPageChanged(int index) {
    statistics?.viewed();
    statistics?.swiped();

    loader.refreshTries = 0;

    loader.index = index;

    pageChange?.call(this);
    loader.loadNext(index);

    // scrollUntill?.call(index);

    // loader.loadCells(_container!.context, index);

    // final c = loader.drawCell(index);

    // const WindowApi().setTitle(c.widgets.alias(false));
  }

  @override
  Widget inject(Widget child) {
    if (wrapNotifiers != null) {
      return wrapNotifiers!(child);
    }

    return child;
  }

  @override
  Widget buildBody(BuildContext context) {
    assert(_container != null);

    final child = PhotoViewGalleryBody(
      key: _container!.bodyKey,
      onPressedLeft: null,
      onPressedRight: null,
      onPageChanged: _onPageChanged,
      onLongPress: _onLongPress,
      pageController: _container!.pageController,
      countEvents: loader.countEvents,
      loadingBuilder: (context, event, index) => loadingBuilder(
        context,
        event,
        index,
      ),
      loader: loader,
      itemCount: loader.count,
      onTap: _container!.flipShowAppBar,
    );

    return child;
  }

  void _onLongPress() {
    if (download == null) {
      return;
    }

    HapticFeedback.vibrate();
    download!(loader.index);
  }
}

// class ContentIndexMetadataHolder extends StatefulWidget {
//   const ContentIndexMetadataHolder({
//     super.key,
//     required this.getContent,
//     required this.currentIndex,
//     required this.indexEvents,
//     required this.wrapNotifiers,
//     required this.countEvents,
//     required this.currentCount,
//     required this.child,
//   });

//   final ContentGetter getContent;

//   final int currentIndex;
//   final int currentCount;

//   final Stream<int> indexEvents;
//   final Stream<int> countEvents;

//   final NotifierWrapper? wrapNotifiers;

//   final Widget child;

//   @override
//   State<ContentIndexMetadataHolder> createState() =>
//       _ContentIndexMetadataHolderState();
// }

// class _ContentIndexMetadataHolderState
//     extends State<ContentIndexMetadataHolder> {
//   late final StreamSubscription<int> indexEvents;
//   late final StreamSubscription<int> countEvents;

//   late _ContentToMetadata currentMetadata;
//   int refreshCounts = 0;

//   @override
//   void initState() {
//     super.initState();

//     indexEvents = widget.indexEvents.listen((newIndex) {
//       currentMetadata = _ContentToMetadata(
//         indexEvents: widget.indexEvents,
//         countEvents: widget.countEvents,
//         content: widget.getContent(newIndex)!,
//         getContent: widget.getContent,
//         wrapNotifiers: widget.wrapNotifiers,
//         index: newIndex,
//         count: currentMetadata.count,
//       );

//       refreshCounts += 1;

//       setState(() {});
//     });

//     countEvents = widget.countEvents.listen((newCount) {
//       currentMetadata = _ContentToMetadata(
//         indexEvents: widget.indexEvents,
//         countEvents: widget.countEvents,
//         content: widget.getContent(currentMetadata.index)!,
//         getContent: widget.getContent,
//         wrapNotifiers: widget.wrapNotifiers,
//         index: currentMetadata.index,
//         count: newCount,
//       );

//       refreshCounts += 1;

//       setState(() {});
//     });

//     currentMetadata = _ContentToMetadata(
//       indexEvents: widget.indexEvents,
//       countEvents: widget.countEvents,
//       content: widget.getContent(widget.currentIndex)!,
//       getContent: widget.getContent,
//       wrapNotifiers: widget.wrapNotifiers,
//       count: widget.currentCount,
//       index: widget.currentIndex,
//     );
//   }

//   @override
//   void dispose() {
//     indexEvents.cancel();
//     countEvents.cancel();

//     super.dispose();
//   }

//   // ImageProvider? _getThumbnail(int i) =>
//   //     widget.getContent(i)?.widgets.tryAsThumbnailable(null);

//   @override
//   Widget build(BuildContext context) {
//     return ThumbnailsNotifier(
//       provider: _getThumbnail,
//       child: CurrentIndexMetadataNotifier(
//         metadata: currentMetadata,
//         refreshTimes: refreshCounts,
//         child: widget.child,
//       ),
//     );
//   }
// }

// class _ContentToMetadata implements CurrentIndexMetadata {
//   const _ContentToMetadata({
//     required this.content,
//     required this.index,
//     required this.getContent,
//     required this.countEvents,
//     required this.indexEvents,
//     required this.wrapNotifiers,
//     required this.count,
//   });

//   final NotifierWrapper? wrapNotifiers;
//   final ContentGetter getContent;
//   final Stream<int> indexEvents;
//   final Stream<int> countEvents;

//   @override
//   final int count;

//   @override
//   bool get isVideo => content is NetVideo;

//   @override
//   Key get uniqueKey => content.widgets.uniqueKey();

//   @override
//   final int index;
//   final Contentable content;

//   @override
//   List<ImageViewAction> actions(BuildContext context) =>
//       content.widgets.tryAsActionable(context);

//   @override
//   List<NavigationAction> appBarButtons(BuildContext context) =>
//       content.widgets.tryAsAppBarButtonable(context);

//   @override
//   Widget? openMenuButton(BuildContext context) {
//     return ImageViewFab(
//       openBottomSheet: (context) {
//         return showModalBottomSheet<void>(
//           context: context,
//           isScrollControlled: true,
//           builder: (sheetContext) {
//             final child = ExitOnPressRoute(
//               exit: () {
//                 Navigator.of(sheetContext).pop();
//                 ExitOnPressRoute.exitOf(context);
//               },
//               child: PauseVideoNotifierHolder(
//                 state: PauseVideoNotifier.stateOf(context),
//                 child: ImageTagsNotifier(
//                   tags: ImageTagsNotifier.of(context),
//                   child: Padding(
//                     padding: EdgeInsets.only(
//                       top: 8,
//                       bottom: MediaQuery.viewPaddingOf(context).bottom + 12,
//                     ),
//                     child: SizedBox(
//                       width: MediaQuery.sizeOf(sheetContext).width,
//                       child: _CellContent(
//                         firstContent: (CurrentIndexMetadata.of(context)
//                                 as _ContentToMetadata)
//                             .content,
//                         firstIndex: index,
//                         getContent: getContent,
//                         indexEvents: indexEvents,
//                         countEvents: countEvents,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );

//             if (wrapNotifiers != null) {
//               return wrapNotifiers!(child);
//             }

//             return child;
//           },
//         );
//       },
//     );
//   }

//   // @override
//   // List<Sticker> stickers(BuildContext context) =>
//   //     content.widgets.tryAsStickerable(context, true);
// }

// class _CellContent extends StatefulWidget {
//   const _CellContent({
//     // super.key,
//     required this.indexEvents,
//     required this.getContent,
//     required this.countEvents,
//     required this.firstContent,
//     required this.firstIndex,
//   });

//   final Contentable firstContent;
//   final int firstIndex;
//   final Stream<int> indexEvents;
//   final Stream<int> countEvents;
//   final ContentGetter getContent;

//   @override
//   State<_CellContent> createState() => __CellContentState();
// }

// class __CellContentState extends State<_CellContent> {
//   late final StreamSubscription<int> countEvents;
//   late final StreamSubscription<int> indexEvents;

//   late Contentable content;

//   late int currentIndex;

//   int refreshes = 0;

//   @override
//   void initState() {
//     super.initState();

//     currentIndex = widget.firstIndex;

//     content = widget.firstContent;

//     indexEvents = widget.indexEvents.listen((newContent) {
//       setState(() {
//         content = widget.getContent(newContent)!;
//         currentIndex = newContent;
//       });
//     });

//     countEvents = widget.countEvents.listen((newCount) {
//       final newContent = widget.getContent(currentIndex);
//       if (newContent == null) {
//         return;
//       }

//       setState(() {
//         content = newContent;
//         refreshes += 1;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     countEvents.cancel();
//     indexEvents.cancel();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return KeyedSubtree(
//       key: ValueKey(refreshes),
//       child: content.widgets.tryAsInfoable(context) ?? const SizedBox.shrink(),
//     );
//   }
// }

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "image_view.dart";

class ImageViewBody extends StatefulWidget {
  const ImageViewBody({
    super.key,
    required this.onPageChanged,
    required this.pageController,
    required this.builder,
    required this.loadingBuilder,
    required this.itemCount,
    required this.onLongPress,
    required this.onTap,
    required this.onPressedLeft,
    required this.onPressedRight,
    required this.countEvents,
  });

  final int itemCount;
  final Stream<int> countEvents;

  final PageController pageController;
  final ContentIdxCallback onPageChanged;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  final VoidCallback? onPressedRight;
  final VoidCallback? onPressedLeft;

  final PhotoViewGalleryPageOptions Function(BuildContext, int) builder;
  final Widget Function(BuildContext, ImageChunkEvent?, int) loadingBuilder;

  @override
  State<ImageViewBody> createState() => _ImageViewBodyState();
}

class _ImageViewBodyState extends State<ImageViewBody> {
  late final StreamSubscription<int> countEvents;

  int count = 0;

  @override
  void initState() {
    super.initState();

    count = widget.itemCount;

    countEvents = widget.countEvents.listen((newCount) {
      setState(() {
        count = newCount;
      });
    });
  }

  @override
  void dispose() {
    countEvents.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ;
    return GestureDeadZones(
      left: true,
      right: true,
      onPressedRight: widget.onPressedRight,
      onPressedLeft: widget.onPressedLeft,
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        onTap: widget.onTap,
        child: _PhotoViewGallery.builder(
          loadingBuilder: widget.loadingBuilder,
          enableRotation: true,
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          onPageChanged: widget.onPageChanged,
          pageController: widget.pageController,
          itemCount: count,
          builder: widget.builder,
        ),
      ),
    );
  }
}

class _PhotoViewGallery extends StatefulWidget {
  const _PhotoViewGallery.builder({
    super.key,
    required this.itemCount,
    required this.builder,
    required this.pageController,
    required this.loadingBuilder,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.allowImplicitScrolling = false,
    this.pageSnapping = true,
  });

  final int itemCount;

  final PhotoViewGalleryBuilder builder;

  final ScrollPhysics? scrollPhysics;

  final Widget Function(
    BuildContext context,
    ImageChunkEvent? event,
    int idx,
  ) loadingBuilder;

  final BoxDecoration? backgroundDecoration;

  final bool wantKeepAlive;

  final bool gaplessPlayback;

  final bool reverse;

  final PageController pageController;

  final PhotoViewGalleryPageChangedCallback? onPageChanged;

  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;

  final bool enableRotation;

  final Size? customSize;

  final Axis scrollDirection;

  final bool allowImplicitScrolling;

  final bool pageSnapping;

  @override
  State<_PhotoViewGallery> createState() => _PhotoViewGalleryState();
}

class _PhotoViewGalleryState extends State<_PhotoViewGallery> {
  PageController get _controller => widget.pageController;

  void scaleStateChangedCallback(PhotoViewScaleState scaleState) {
    widget.scaleStateChangedCallback?.call(scaleState);
  }

  int get actualPage {
    return _controller.hasClients ? _controller.page!.floor() : 0;
  }

  int get itemCount => widget.itemCount;

  Widget _buildItem(BuildContext context, int index) {
    final pageOption = widget.builder(context, index);
    final isCustomChild = pageOption.child != null;

    final PhotoView photoView = isCustomChild
        ? PhotoView.customChild(
            key: ObjectKey(index),
            childSize: pageOption.childSize,
            backgroundDecoration: widget.backgroundDecoration,
            wantKeepAlive: widget.wantKeepAlive,
            controller: pageOption.controller,
            scaleStateController: pageOption.scaleStateController,
            customSize: widget.customSize,
            heroAttributes: pageOption.heroAttributes,
            scaleStateChangedCallback: scaleStateChangedCallback,
            enableRotation: widget.enableRotation,
            initialScale: pageOption.initialScale,
            minScale: pageOption.minScale,
            maxScale: pageOption.maxScale,
            scaleStateCycle: pageOption.scaleStateCycle,
            onTapUp: pageOption.onTapUp,
            onTapDown: pageOption.onTapDown,
            onScaleEnd: pageOption.onScaleEnd,
            gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
            tightMode: pageOption.tightMode,
            filterQuality: pageOption.filterQuality,
            basePosition: pageOption.basePosition,
            disableGestures: pageOption.disableGestures,
            child: pageOption.child,
          )
        : PhotoView(
            key: ObjectKey(index),
            imageProvider: pageOption.imageProvider,
            loadingBuilder: (context, chunk) => widget.loadingBuilder(
              context,
              chunk,
              index,
            ),
            backgroundDecoration: widget.backgroundDecoration,
            wantKeepAlive: widget.wantKeepAlive,
            controller: pageOption.controller,
            scaleStateController: pageOption.scaleStateController,
            customSize: widget.customSize,
            semanticLabel: pageOption.semanticLabel,
            gaplessPlayback: widget.gaplessPlayback,
            heroAttributes: pageOption.heroAttributes,
            scaleStateChangedCallback: scaleStateChangedCallback,
            enableRotation: widget.enableRotation,
            initialScale: pageOption.initialScale,
            minScale: pageOption.minScale,
            maxScale: pageOption.maxScale,
            scaleStateCycle: pageOption.scaleStateCycle,
            onTapUp: pageOption.onTapUp,
            onTapDown: pageOption.onTapDown,
            onScaleEnd: pageOption.onScaleEnd,
            gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
            tightMode: pageOption.tightMode,
            filterQuality: pageOption.filterQuality,
            basePosition: pageOption.basePosition,
            disableGestures: pageOption.disableGestures,
            errorBuilder: pageOption.errorBuilder,
          );

    return ClipRect(
      child: photoView,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PhotoViewGestureDetectorScope(
      axis: widget.scrollDirection,
      child: PageView.builder(
        reverse: widget.reverse,
        controller: _controller,
        onPageChanged: widget.onPageChanged,
        itemCount: itemCount,
        itemBuilder: _buildItem,
        scrollDirection: widget.scrollDirection,
        physics: widget.scrollPhysics,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        pageSnapping: widget.pageSnapping,
      ),
    );
  }
}

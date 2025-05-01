// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io";

import "package:azari/src/generated/platform/platform_api.g.dart" as platform;
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/services/impl/io/image_view_body.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/image_view/video/video_controls_controller.dart";
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:photo_view/photo_view_gallery.dart";

part "pigeon_gallery_data_impl.dart";

class _StateContainer {
  _StateContainer({
    required this.context,
    required this.flipShowAppBar,
    required int initialPage,
    required this.playAnimationLeft,
    required this.playAnimationRight,
  }) : pageController = PageController(initialPage: initialPage);

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

class DefaultStateController extends ImageViewStateController {
  DefaultStateController({
    required this.loader,
    this.ignoreLoadingBuilder = false,
    this.pageChange,
    this.statistics,
    this.download,
    this.wrapNotifiers,
  });

  final bool ignoreLoadingBuilder;

  final ImageViewStatistics? statistics;

  final ContentIdxCallback? download;

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
      flipShowAppBar: flipShowAppBar,
      context: context,
    );

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

  void _onPageChanged(int index) {
    statistics?.viewed();
    statistics?.swiped();

    loader.refreshTries = 0;

    loader.index = index;

    pageChange?.call(this);
    loader.loadNext(index);
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

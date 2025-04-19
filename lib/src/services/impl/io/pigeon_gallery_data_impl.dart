// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io";

import "package:azari/src/generated/platform/platform_api.g.dart" as platform;
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/image_view/video/video_controls_controller.dart";
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";

class PlatformImageViewStateImpl
    implements
        platform.FlutterGalleryData,
        ImageViewLoader,
        ImageViewStateController,
        platform.GalleryVideoEvents {
  PlatformImageViewStateImpl({
    required this.source,
    required this.wrapNotifiers,
    required this.onTagPressed,
    required this.onTagLongPressed,
  }) {
    _events = source.backingStorage.watch((_) {
      if (Platform.isAndroid) {
        platform.PlatformGalleryEvents().metadataChanged();
      }
      _indexChanges.add(currentIndex);
    });
  }

  final NotifierWrapper wrapNotifiers;
  final void Function(BuildContext, String)? onTagPressed;
  final void Function(BuildContext, String)? onTagLongPressed;

  late final StreamSubscription<void> _events;
  final _indexChanges = StreamController<int>.broadcast();
  final _videoChanges = StreamController<_VideoPlayerEvent>.broadcast();

  int currentIndex = 0;

  final ResourceSource<int, File> source;

  @override
  int get count => source.count;

  @override
  Stream<int> get countEvents => source.backingStorage.countEvents;

  @override
  ImageViewWidgets? get(int i) => source.forIdxUnsafe(i);

  @override
  int get index => currentIndex;

  @override
  Stream<int> get indexEvents => _indexChanges.stream;

  @override
  ImageViewLoader get loader => this;

  @override
  List<ImageTag> tagsFor(int i) {
    final filename = source.forIdxUnsafe(i).name;
    final postTags = const LocalTagsService().get(filename);
    if (postTags.isEmpty) {
      return const [];
    }

    return postTags
        .map(
          (e) => ImageTag(
            e,
            type: const TagManagerService().pinned.exists(e)
                ? ImageTagType.favorite
                : const TagManagerService().excluded.exists(e)
                    ? ImageTagType.excluded
                    : ImageTagType.normal,
            onTap: onTagPressed != null
                ? (context) => onTagPressed!(context, e)
                : null,
            onLongTap: onTagLongPressed != null
                ? (context) => onTagLongPressed!(context, e)
                : null,
          ),
        )
        .toList();
  }

  @override
  Stream<void> tagsEventsFor(int i) => const TagManagerService().pinned.events;

  @override
  Future<platform.DirectoryFile> atIndex(int index) =>
      Future.value(source.forIdxUnsafe(index).toDirectoryFile());

  @override
  Future<platform.GalleryMetadata> metadata() =>
      Future.value(platform.GalleryMetadata(count: source.count));

  @override
  void setCurrentIndex(int index) {
    currentIndex = index;
    _indexChanges.add(index);
  }

  void dispose() {
    _events.cancel();
    _indexChanges.close();
    _videoChanges.close();
  }

  @override
  void bind(
    BuildContext context, {
    required int startingIndex,
    required VoidCallback playAnimationLeft,
    required VoidCallback playAnimationRight,
    required VoidCallback flipShowAppBar,
  }) {
    currentIndex = startingIndex;
    _indexChanges.add(currentIndex);
  }

  @override
  void seekTo(int i) {
    platform.PlatformGalleryEvents().seekToIndex(i);
  }

  @override
  void unbind() {}

  @override
  Widget inject(Widget child) => wrapNotifiers(child);

  @override
  Widget buildBody(BuildContext context) {
    return _ImageViewBodyPlatformView(
      videoEvents: _videoChanges.stream,
      controls: VideoControlsNotifier.of(context),
      startingCell: currentIndex,
    );
  }

  @override
  void durationEvent(int duration) {
    _videoChanges.add(_DurationEvent(duration));
  }

  @override
  void playbackStateEvent(platform.VideoPlaybackState state) {
    _videoChanges.add(_PlaybackStateEvent(state));
  }

  @override
  void volumeEvent(double volume) {
    _videoChanges.add(_VolumeEvent(volume));
  }

  @override
  void progressEvent(int progress) {
    _videoChanges.add(_ProgressEvent(progress));
  }

  @override
  void loopingEvent(bool looping) {
    _videoChanges.add(_LoopingEvent(looping));
  }

  @override
  Future<double?> initialVolume() =>
      Future.value(VideoSettingsService.safe()?.current.volume);
}

sealed class _VideoPlayerEvent {
  const _VideoPlayerEvent();
}

class _VolumeEvent implements _VideoPlayerEvent {
  const _VolumeEvent(this.volume);

  final double volume;
}

class _DurationEvent implements _VideoPlayerEvent {
  const _DurationEvent(this.duration);

  final int duration;
}

class _PlaybackStateEvent implements _VideoPlayerEvent {
  const _PlaybackStateEvent(this.state);

  final platform.VideoPlaybackState state;
}

class _ProgressEvent implements _VideoPlayerEvent {
  const _ProgressEvent(this.duration);

  final int duration;
}

class _LoopingEvent implements _VideoPlayerEvent {
  const _LoopingEvent(this.looping);

  final bool looping;
}

// class _FileMetadataProvider extends StatefulWidget {
//   const _FileMetadataProvider({
//     // super.key,
//     required this.currentIndex,
//     required this.indexEvents,
//     required this.source,
//     required this.wrapNotifiers,
//     required this.currentCount,
//     required this.countEvents,
//     required this.child,
//   });

//   final int currentIndex;
//   final int currentCount;

//   final ResourceSource<int, File> source;

//   final Stream<int> indexEvents;
//   final Stream<int> countEvents;

//   final NotifierWrapper? wrapNotifiers;

//   final Widget child;

//   @override
//   State<_FileMetadataProvider> createState() => __FileMetadataProviderState();
// }

// class __FileMetadataProviderState extends State<_FileMetadataProvider> {
//   late final StreamSubscription<int> _eventsIndex;
//   late final StreamSubscription<int> _eventsCount;

//   late _FileToMetadata metadata;
//   int refreshTimes = 0;

//   @override
//   void initState() {
//     super.initState();

//     metadata = _FileToMetadata(
//       file: widget.source.forIdxUnsafe(widget.currentIndex),
//       index: widget.currentIndex,
//       count: widget.currentCount,
//       wrapNotifiers: widget.wrapNotifiers,
//     );

//     _eventsIndex = widget.indexEvents.listen((newIndex) {
//       metadata = _FileToMetadata(
//         file: widget.source.forIdxUnsafe(newIndex),
//         count: metadata.count,
//         index: newIndex,
//         wrapNotifiers: widget.wrapNotifiers,
//       );

//       refreshTimes += 1;

//       setState(() {});
//     });

//     _eventsCount = widget.countEvents.listen((newCount) {
//       metadata = _FileToMetadata(
//         file: metadata.file,
//         index: metadata.index,
//         count: newCount,
//         wrapNotifiers: widget.wrapNotifiers,
//       );

//       refreshTimes += 1;

//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _eventsIndex.cancel();
//     _eventsCount.cancel();

//     super.dispose();
//   }

//   ImageProvider _getThumbnail(int i) =>
//       widget.source.forIdxUnsafe(i).thumbnail();

//   @override
//   Widget build(BuildContext context) {
//     return ThumbnailsNotifier(
//       provider: _getThumbnail,
//       child: CurrentIndexMetadataNotifier(
//         metadata: metadata,
//         refreshTimes: refreshTimes,
//         child: widget.child,
//       ),
//     );
//   }
// }

// class _FileToMetadata implements CurrentIndexMetadata {
//   const _FileToMetadata({
//     required this.file,
//     required this.index,
//     required this.wrapNotifiers,
//     required this.count,
//   });

//   final NotifierWrapper? wrapNotifiers;
//   final File file;

//   @override
//   final int index;

//   @override
//   final int count;

//   @override
//   bool get isVideo => file.isVideo;

//   @override
//   Key get uniqueKey => file.uniqueKey();

//   @override
//   List<ImageViewAction> actions(BuildContext context) => file.actions(context);

//   @override
//   List<NavigationAction> appBarButtons(BuildContext context) =>
//       file.appBarButtons(context);

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
//                       child: file.info(context),
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
//   // List<Sticker> stickers(BuildContext context) => file.stickers(context, true);
// }

class _ImageViewBodyPlatformView extends StatefulWidget {
  const _ImageViewBodyPlatformView({
    // super.key,
    required this.controls,
    required this.startingCell,
    required this.videoEvents,
  });

  final Stream<_VideoPlayerEvent> videoEvents;
  final VideoControlsController controls;
  final int startingCell;

  @override
  State<_ImageViewBodyPlatformView> createState() =>
      __ImageViewBodyPlatformViewState();
}

class __ImageViewBodyPlatformViewState
    extends State<_ImageViewBodyPlatformView> {
  late final StreamSubscription<_VideoPlayerEvent> events;
  late final StreamSubscription<VideoControlsEvent> controlsEvents;

  @override
  void initState() {
    super.initState();

    final galleryEvents = platform.PlatformGalleryEvents();

    controlsEvents = widget.controls.events.listen(
      (e) => switch (e) {
        VolumeButton() => galleryEvents.volumeButtonPressed(null),
        FullscreenButton() => null,
        PlayButton() => galleryEvents.playButtonPressed(),
        LoopingButton() => galleryEvents.loopingButtonPressed(),
        AddDuration() =>
          galleryEvents.durationChanged(e.durationSeconds.ceil() * 1000),
      },
    );

    events = widget.videoEvents.listen(
      (e) {
        return switch (e) {
          _VolumeEvent() => widget.controls.setVolume(e.volume),
          _DurationEvent() =>
            widget.controls.setDuration(Duration(milliseconds: e.duration)),
          _ProgressEvent() =>
            widget.controls.setProgress(Duration(milliseconds: e.duration)),
          _LoopingEvent() => VideoSettingsService.available
              ? ()
              : const VideoSettingsService().add(
                  const VideoSettingsService().current.copy(looping: e.looping),
                ),
          _PlaybackStateEvent() => widget.controls.setPlayState(
              switch (e.state) {
                platform.VideoPlaybackState.stopped => PlayState.stopped,
                platform.VideoPlaybackState.playing => PlayState.isPlaying,
                platform.VideoPlaybackState.buffering => PlayState.buffering,
              },
            ),
        };
      },
    );
  }

  @override
  void dispose() {
    events.cancel();
    controlsEvents.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: PlatformViewLink(
          viewType: "gallery",
          surfaceFactory: (context, controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              hitTestBehavior: PlatformViewHitTestBehavior.translucent,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            );
          },
          onCreatePlatformView: (params) {
            return PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: params.viewType,
              creationParams: {
                "id": widget.startingCell,
              },
              creationParamsCodec: const StandardMessageCodec(),
              layoutDirection: TextDirection.ltr,
            )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create();
          },
        ),
      ),
    );
  }
}

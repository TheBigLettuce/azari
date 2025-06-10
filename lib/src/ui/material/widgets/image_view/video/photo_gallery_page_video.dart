// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view_notifiers.dart";
import "package:azari/src/ui/material/widgets/image_view/video/player_widget_controller.dart";
import "package:chewie/chewie.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:video_player/video_player.dart";

class PhotoGalleryPageVideo extends StatefulWidget {
  const PhotoGalleryPageVideo({
    super.key,
    required this.url,
    required this.localVideo,
    required this.networkThumb,
  });

  final String url;
  final ImageProvider? networkThumb;
  final bool localVideo;

  @override
  State<PhotoGalleryPageVideo> createState() => _PhotoGalleryPageVideoState();
}

class _PhotoGalleryPageVideoState extends State<PhotoGalleryPageVideo> {
  StreamSubscription<PlayerButtonEvent>? buttonEvents;

  late VideoPlayerController controller;
  ChewieController? chewieController;
  bool disposed = false;
  Object? error;

  late PlayerWidgetController playerControls;

  @override
  void initState() {
    super.initState();

    newController();

    _initController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    playerControls = PlayerWidgetControllerNotifier.of(context);
    buttonEvents ??= playerControls.buttonEvents.listen((event) {
      switch (event) {
        case VolumeButton():
          double newVolume;

          if (controller.value.volume > 0) {
            newVolume = 0;
          } else {
            newVolume = 1;
          }

          controller.setVolume(newVolume);

          VideoSettingsService.safe()?.current
              .copy(volume: newVolume)
              .maybeSave();
        case FullscreenButton():
          final orientation = MediaQuery.orientationOf(context);
          if (orientation == Orientation.landscape) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitDown,
              DeviceOrientation.portraitUp,
            ]);
          } else {
            AppBarVisibilityNotifier.maybeToggleOf(context);

            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          }
        case PlayButton():
          if (controller.value.isBuffering) {
            return;
          }

          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        case LoopingButton():
          final newLooping = !controller.value.isLooping;

          controller.setLooping(newLooping);
          VideoSettingsService.safe()?.current
              .copy(looping: newLooping)
              .maybeSave();
        case AddDuration():
          controller.seekTo(
            controller.value.position +
                Duration(seconds: event.durationSeconds.toInt()),
          );
      }
    });
  }

  void newController() {
    if (widget.localVideo) {
      controller = VideoPlayerController.contentUri(
        Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }
  }

  Future<void> _initController() {
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      playerControls.clear();
      playerControls.playState = PlayState.buffering;
    });

    return controller
        .initialize()
        .then((value) {
          if (!disposed) {
            controller.addListener(_listener);

            final videoSettings = VideoSettingsService.safe()?.current;

            controller.setVolume(videoSettings?.volume ?? 1);

            setState(() {
              chewieController?.dispose();
              chewieController = ChewieController(
                videoPlayerController: controller,
                aspectRatio: controller.value.aspectRatio,
                looping: videoSettings?.looping ?? true,
                allowPlaybackSpeedChanging: false,
                showOptions: false,
                showControls: false,
                allowMuting: false,
                zoomAndPan: true,
                showControlsOnInitialize: false,
              );
            });

            playerControls.duration = controller.value.duration;

            chewieController!.play().onError((e, stackTrace) {
              if (!disposed) {
                setState(() {
                  error = e;
                });
              }
            });
          }
        })
        .onError((e, stackTrace) {
          if (!disposed) {
            setState(() {
              error = e;
            });
          }
        });
  }

  Duration? prevProgress;
  PlayState? prevPlayState;

  void _listener() {
    final value = controller.value;

    final newPlayState = value.isBuffering
        ? PlayState.buffering
        : value.isPlaying
        ? PlayState.isPlaying
        : PlayState.stopped;

    final newProgress = value.position;

    if (prevProgress != newProgress) {
      prevProgress = newProgress;

      playerControls.duration = controller.value.duration;
      playerControls.progress = newProgress;
    }

    if (prevPlayState != newPlayState) {
      prevPlayState = newPlayState;

      playerControls.playState = newPlayState;
    }
  }

  @override
  void dispose() {
    buttonEvents?.cancel();
    disposed = true;
    controller.dispose();
    chewieController?.dispose();

    super.dispose();
  }

  String tryFormatError() {
    if (error is PlatformException) {
      return (error! as PlatformException).message ?? "";
    }

    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return PauseVideoNotifier.of(context)
        ? _BlankVideo(
            controller: controller,
            isPreviouslyPlayed: controller.value.isPlaying,
          )
        : error != null
        ? LoadingErrorWidget(
            error: tryFormatError(),
            short: false,
            refresh: () {
              controller.dispose();
              newController();
              _initController();
              setState(() {});
            },
          )
        : chewieController == null
        ? widget.networkThumb != null
              ? Image(
                  image: widget.networkThumb!,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.contain,
                )
              : const Center(child: CircularProgressIndicator())
        : GestureDetector(
            onDoubleTap: () {
              if (!disposed) {
                if (chewieController!.isPlaying) {
                  chewieController!.pause();
                } else {
                  chewieController!.play();
                }
              }
            },
            child: Chewie(controller: chewieController!),
          );
  }
}

class _BlankVideo extends StatefulWidget {
  const _BlankVideo({
    required this.controller,
    required this.isPreviouslyPlayed,
  });
  final VideoPlayerController controller;
  final bool isPreviouslyPlayed;

  @override
  State<_BlankVideo> createState() => __BlankVideoState();
}

class __BlankVideoState extends State<_BlankVideo> {
  @override
  void initState() {
    super.initState();

    widget.controller.pause();
  }

  @override
  void dispose() {
    if (widget.isPreviouslyPlayed) {
      widget.controller.play();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

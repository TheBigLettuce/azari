// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:chewie/chewie.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/widgets/image_view/video/video_controls.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/loading_error_widget.dart";
import "package:video_player/video_player.dart";

class PhotoGalleryPageVideo extends StatefulWidget
    with DbConnHandle<VideoSettingsService> {
  const PhotoGalleryPageVideo({
    super.key,
    required this.url,
    required this.localVideo,
    required this.db,
  });

  @override
  final VideoSettingsService db;

  final String url;
  final bool localVideo;

  @override
  State<PhotoGalleryPageVideo> createState() => _PhotoGalleryPageVideoState();
}

class _PhotoGalleryPageVideoState extends State<PhotoGalleryPageVideo>
    with VideoSettingsDbScope<PhotoGalleryPageVideo> {
  late VideoPlayerController controller;
  ChewieController? chewieController;
  bool disposed = false;
  Object? error;

  @override
  void initState() {
    super.initState();

    newController();

    _initController();
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
    return controller.initialize().then((value) {
      if (!disposed) {
        final videoSettings = current;

        controller.setVolume(videoSettings.volume);

        setState(() {
          chewieController?.dispose();
          chewieController = ChewieController(
            videoPlayerController: controller,
            aspectRatio: controller.value.aspectRatio,
            looping: videoSettings.looping,
            allowPlaybackSpeedChanging: false,
            showOptions: false,
            showControls: false,
            allowMuting: false,
            zoomAndPan: true,
            showControlsOnInitialize: false,
          );
        });

        chewieController!.play().onError((e, stackTrace) {
          if (!disposed) {
            setState(() {
              error = e;
            });
          }
        });
      }
    }).onError((e, stackTrace) {
      if (!disposed) {
        setState(() {
          error = e;
        });
      }
    });
  }

  @override
  void dispose() {
    disposed = true;
    controller.pause();
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
                ? const Center(child: CircularProgressIndicator())
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
                    child: Stack(
                      children: [
                        Chewie(controller: chewieController!),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: VideoControls(
                            controller: controller,
                            db: widget.db,
                            setState: setState,
                          ),
                        ),
                      ],
                    ),
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

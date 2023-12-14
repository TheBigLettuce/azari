// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/loading_error_widget.dart';
import 'package:gallery/src/widgets/notifiers/app_bar_visibility.dart';
import 'package:gallery/src/widgets/notifiers/pause_video.dart';
import 'package:video_player/video_player.dart';

class PhotoGalleryPageVideo extends StatefulWidget {
  final String url;
  final bool localVideo;
  const PhotoGalleryPageVideo({
    super.key,
    required this.url,
    required this.localVideo,
  });

  @override
  State<PhotoGalleryPageVideo> createState() => _PhotoGalleryPageVideoState();
}

class _PhotoGalleryPageVideoState extends State<PhotoGalleryPageVideo> {
  late final VideoPlayerController controller;
  ChewieController? chewieController;
  bool disposed = false;
  Object? error;

  @override
  void initState() {
    super.initState();

    if (widget.localVideo) {
      controller = VideoPlayerController.contentUri(Uri.parse(widget.url),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse(widget.url),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    }

    _initController();
  }

  void _initController() async {
    controller.initialize().then((value) {
      if (!disposed) {
        setState(() {
          chewieController = ChewieController(
              // materialProgressColors:
              //     ChewieProgressColors(backgroundColor: widget.backgroundColor),
              videoPlayerController: controller,
              aspectRatio: controller.value.aspectRatio,
              autoInitialize: false,
              looping: true,
              allowPlaybackSpeedChanging: false,
              showOptions: false,
              showControls: false,
              allowMuting: false,
              zoomAndPan: true,
              showControlsOnInitialize: false,
              autoPlay: false);
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
    controller.dispose();
    if (chewieController != null) {
      chewieController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PauseVideoNotifier.of(context)
        ? _BlankVideo(
            controller: controller,
            isPreviouslyPlayed: controller.value.isPlaying)
        : error != null
            ? const LoadingErrorWidget(error: "")
            : chewieController == null
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    // onTap: widget.onTap,
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
                        Animate(
                          effects: const [
                            FadeEffect(
                                begin: 1,
                                end: 0,
                                duration: Duration(milliseconds: 500))
                          ],
                          autoPlay: false,
                          target: AppBarVisibilityNotifier.of(context) ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: !AppBarVisibilityNotifier.of(context),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 60,
                                child: Card.filled(
                                  color: Theme.of(context)
                                      .appBarTheme
                                      .backgroundColor,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (controller.value.isBuffering) {
                                            return;
                                          }

                                          if (controller.value.isPlaying) {
                                            controller.pause();
                                          } else {
                                            controller.play();
                                          }

                                          setState(() {});
                                        },
                                        icon: controller.value.isPlaying
                                            ? const Icon(Icons.stop_circle)
                                            : const Icon(Icons.play_arrow),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          if (controller.value.volume > 0) {
                                            controller.setVolume(0);
                                          } else {
                                            controller.setVolume(1);
                                          }

                                          setState(() {});
                                        },
                                        icon: controller.value.volume == 0
                                            ? const Icon(
                                                Icons.volume_off_outlined)
                                            : const Icon(
                                                Icons.volume_up_outlined),
                                      ),
                                      _VideoTime(controller: controller)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
  }
}

class _VideoTime extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoTime({super.key, required this.controller});

  @override
  State<_VideoTime> createState() => __VideoTimeState();
}

class __VideoTimeState extends State<_VideoTime> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);

    super.dispose();
  }

  void _update() {
    try {
      setState(() {});
    } catch (_) {}
  }

  String _minutesSeconds(Duration duration) {
    return "${duration.inMinutes}.${duration.inSeconds - (duration.inMinutes * 60)}";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        "${_minutesSeconds(widget.controller.value.position)} /\n${_minutesSeconds(widget.controller.value.duration)}",
        style: TextStyle(
            color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
      ),
    );
  }
}

class _BlankVideo extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isPreviouslyPlayed;

  const _BlankVideo(
      {super.key, required this.controller, required this.isPreviouslyPlayed});

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

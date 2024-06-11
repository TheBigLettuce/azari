// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:video_player/video_player.dart";

class VideoControls extends StatelessWidget {
  const VideoControls({
    super.key,
    required this.controller,
    required this.setState,
    required this.db,
  });

  final VideoSettingsService db;
  final VideoPlayerController controller;
  final void Function(void Function()) setState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarVisibility = AppBarVisibilityNotifier.of(context);

    return Animate(
      effects: const [
        FadeEffect(begin: 1, end: 0, duration: Duration(milliseconds: 500)),
      ],
      autoPlay: false,
      target: appBarVisibility ? 0 : 1,
      child: IgnorePointer(
        ignoring: !appBarVisibility,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 60,
            child: Card.filled(
              color: theme.appBarTheme.backgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PlayButton(
                    controller: controller,
                  ),
                  IconButton(
                    onPressed: () {
                      double newVolume;

                      if (controller.value.volume > 0) {
                        newVolume = 0;
                      } else {
                        newVolume = 1;
                      }

                      controller.setVolume(newVolume);

                      db.current.copy(volume: newVolume).save();

                      setState(() {});
                    },
                    icon: controller.value.volume == 0
                        ? const Icon(Icons.volume_off_outlined)
                        : const Icon(Icons.volume_up_outlined),
                  ),
                  IconButton(
                    onPressed: () {
                      final newLooping = !controller.value.isLooping;

                      controller.setLooping(newLooping);
                      db.current.copy(looping: newLooping).save();

                      setState(() {});
                    },
                    icon: Icon(
                      Icons.loop_outlined,
                      color: controller.value.isLooping
                          ? Colors.blue.harmonizeWith(
                              theme.colorScheme.primary,
                            )
                          : null,
                    ),
                  ),
                  Divider(
                    color: theme.iconTheme.color?.withOpacity(0.5),
                  ),
                  _VideoTime(controller: controller),
                  _VideoSeekBackward(controller: controller),
                  _VideoSeekForward(controller: controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_PlayButton> createState() => __PlayButtonState();
}

class __PlayButtonState extends State<_PlayButton> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () {
        if (widget.controller.value.isBuffering) {
          return;
        }

        if (widget.controller.value.isPlaying) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }

        setState(() {});
      },
      icon: widget.controller.value.isBuffering
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue.harmonizeWith(theme.colorScheme.primary),
              ),
            )
          : widget.controller.value.isPlaying
              ? const Icon(Icons.stop_circle_rounded)
              : const Icon(Icons.play_arrow_rounded),
    );
  }
}

class _VideoSeekForward extends StatelessWidget {
  const _VideoSeekForward({
    required this.controller,
  });
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        controller
            .seekTo(controller.value.position + const Duration(seconds: 5));
      },
      icon: const Icon(Icons.fast_forward_rounded),
    );
  }
}

class _VideoSeekBackward extends StatelessWidget {
  const _VideoSeekBackward({
    required this.controller,
  });
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        controller
            .seekTo(controller.value.position - const Duration(seconds: 5));
      },
      icon: const Icon(Icons.fast_rewind_rounded),
    );
  }
}

class _VideoTime extends StatefulWidget {
  const _VideoTime({required this.controller});
  final VideoPlayerController controller;

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
    final secs = duration.inSeconds - (duration.inMinutes * 60);
    final mins = duration.inMinutes > 99 ? 99 : duration.inMinutes;

    return "${mins < 10 ? '0$mins' : mins}:${secs < 10 ? '0$secs' : secs}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: FittedBox(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _minutesSeconds(widget.controller.value.position),
                  style: TextStyle(
                    color: theme.iconTheme.color?.withOpacity(0.6),
                  ),
                ),
                TextSpan(
                  text:
                      "\n${_minutesSeconds(widget.controller.value.duration)}",
                  style: TextStyle(
                    color: theme.iconTheme.color?.withOpacity(0.2),
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

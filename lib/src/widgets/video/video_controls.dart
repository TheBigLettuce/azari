// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/settings/video_settings.dart';
import 'package:video_player/video_player.dart';

import '../notifiers/app_bar_visibility.dart';

class VideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final void Function(void Function()) setState;

  const VideoControls(
      {super.key, required this.controller, required this.setState});

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: const [
        FadeEffect(begin: 1, end: 0, duration: Duration(milliseconds: 500))
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
              color: Theme.of(context).appBarTheme.backgroundColor,
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

                      VideoSettings.changeVolume(newVolume);

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
                      VideoSettings.changeLooping(newLooping);

                      setState(() {});
                    },
                    icon: Icon(
                      Icons.loop_outlined,
                      color: controller.value.isLooping
                          ? Colors.blue.harmonizeWith(
                              Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  _VideoTime(controller: controller)
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
  final VideoPlayerController controller;

  const _PlayButton({super.key, required this.controller});

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
      if (widget.controller.value.isCompleted &&
          !widget.controller.value.isLooping) {
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
      icon: widget.controller.value.isPlaying
          ? const Icon(Icons.stop_circle)
          : const Icon(Icons.play_arrow),
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
    final secs = duration.inSeconds - (duration.inMinutes * 60);
    final mins = duration.inMinutes > 99 ? 99 : duration.inMinutes;

    return "${mins < 10 ? '0$mins' : mins}:${secs < 10 ? '0$secs' : secs}";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: _minutesSeconds(widget.controller.value.position),
              style: TextStyle(
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.6))),
          TextSpan(
              text: "\n${_minutesSeconds(widget.controller.value.duration)}",
              style: TextStyle(
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.2)))
        ]),
      ),
    );
  }
}

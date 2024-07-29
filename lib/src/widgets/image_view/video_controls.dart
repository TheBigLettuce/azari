// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "image_view.dart";

class VideoControls extends StatefulWidget {
  const VideoControls({
    super.key,
    required this.videoControls,
    required this.db,
    required this.child,
  });

  final _VideoControlsControllerImpl videoControls;

  final VideoSettingsService db;

  final Widget child;

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls>
    with TickerProviderStateMixin {
  late final StreamSubscription<PlayerUpdate> playerUpdatesSubsc;
  late final StreamSubscription<VideoSettingsData> videoSettingsSubsc;

  late final AnimationController animationController;

  final videoTimeKey = GlobalKey<__VideoTimeState>();
  final playButtonKey = GlobalKey<__PlayButtonState>();

  _VideoControlsControllerImpl get controls => widget.videoControls;

  Contentable currentContent = const EmptyContent(ContentWidgets.empty());
  bool appBarVisible = true;

  late VideoSettingsData videoSettings = widget.db.current;

  @override
  void initState() {
    super.initState();

    animationController =
        AnimationController(vsync: this, duration: Durations.medium1);

    playerUpdatesSubsc = controls._playerEvents.stream.listen((update) {
      switch (update) {
        case DurationUpdate():
        case ProgressUpdate():
          videoTimeKey.currentState?._update();
        case PlayStateUpdate():
          playButtonKey.currentState?._update();
        case ClearUpdate():
          playButtonKey.currentState?._update();
          videoTimeKey.currentState?._update();
      }
    });

    videoSettingsSubsc = widget.db.watch((settings) {
      setState(() {
        videoSettings = settings;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    videoSettingsSubsc.cancel();
    playerUpdatesSubsc.cancel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newContent = CurrentContentNotifier.of(context);
    if (newContent != currentContent) {
      currentContent = newContent;
      if (currentContent is AndroidVideo || currentContent is NetVideo) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
    }

    final newAppBarVisible = AppBarVisibilityNotifier.of(context);
    if (appBarVisible != newAppBarVisible) {
      appBarVisible = newAppBarVisible;
    }
  }

  final _timeKey = GlobalKey<__SeekTimeState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom +
        (MediaQuery.orientationOf(context) == Orientation.portrait
            ? 100 + 16
            : 0);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        _SeekTime(
          key: _timeKey,
          bottomPadding: bottomPadding,
          videoControls: widget.videoControls,
        ),
        Animate(
          autoPlay: false,
          effects: const [
            FadeEffect(
              delay: Durations.short1,
              duration: Durations.medium3,
              curve: Easing.linear,
              begin: 0,
              end: 1,
            ),
            SlideEffect(
              duration: Durations.medium1,
              curve: Easing.emphasizedDecelerate,
              begin: Offset(0, 1),
              end: Offset.zero,
            ),
          ],
          controller: animationController,
          child: Builder(
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: bottomPadding,
                ),
                child: Animate(
                  effects: const [
                    FadeEffect(
                      begin: 1,
                      end: 0,
                      duration: Duration(milliseconds: 500),
                    ),
                  ],
                  autoPlay: false,
                  target: appBarVisible ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: !appBarVisible,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: 60,
                        child: Card.filled(
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: GestureDetector(
                            onPanStart: (details) {
                              _timeKey.currentState?.updateDuration(0);
                            },
                            onPanUpdate: (details) {
                              _timeKey.currentState
                                  ?.updateDuration(details.delta.dx);
                            },
                            onPanEnd: (details) {
                              _timeKey.currentState?.finishUpdating();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PlayButton(
                                  key: playButtonKey,
                                  controller: controls,
                                ),
                                IconButton(
                                  onPressed: () {
                                    controls._events.add(const VolumeButton());
                                  },
                                  icon: videoSettings.volume == 0
                                      ? const Icon(Icons.volume_off_outlined)
                                      : const Icon(Icons.volume_up_outlined),
                                ),
                                IconButton(
                                  onPressed: () {
                                    controls._events.add(const LoopingButton());
                                  },
                                  icon: Icon(
                                    Icons.loop_outlined,
                                    color: videoSettings.looping
                                        ? Colors.blue.harmonizeWith(
                                            theme.colorScheme.primary,
                                          )
                                        : null,
                                  ),
                                ),
                                _VideoTime(
                                  key: videoTimeKey,
                                  controller: controls,
                                ),
                                IconButton(
                                  onPressed: () {
                                    controls._events
                                        .add(const FullscreenButton());
                                  },
                                  icon: const Icon(Icons.fullscreen_outlined),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SeekTime extends StatefulWidget {
  const _SeekTime({
    required super.key,
    required this.bottomPadding,
    required this.videoControls,
  });

  final _VideoControlsControllerImpl videoControls;

  final double bottomPadding;

  @override
  State<_SeekTime> createState() => __SeekTimeState();
}

class __SeekTimeState extends State<_SeekTime> {
  double? seekDuration;

  void updateDuration(double d) {
    setState(() {
      if (seekDuration != null) {
        seekDuration = seekDuration! + (d * 0.2);
      } else {
        seekDuration = d;
      }
    });
  }

  void finishUpdating() {
    if (seekDuration != null) {
      widget.videoControls._events.add(AddDuration(seekDuration!));

      setState(() {
        seekDuration = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Animate(
      autoPlay: false,
      target: seekDuration != null ? 1 : 0,
      effects: const [
        FadeEffect(
          begin: 0,
          end: 1,
        ),
      ],
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomPadding + 8 + 60),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: theme.colorScheme.surfaceContainerLow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                "${seekDuration != null && seekDuration!.sign == 1 ? '+' : ''}${l10n.secondsShort((seekDuration ?? 0).truncate())}",
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({
    required super.key,
    required this.controller,
  });

  final _VideoControlsControllerImpl controller;

  @override
  State<_PlayButton> createState() => __PlayButtonState();
}

class __PlayButtonState extends State<_PlayButton> {
  void _update() {
    try {
      setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final playState = widget.controller.playState;

    return IconButton(
      onPressed: playState == null
          ? null
          : () {
              widget.controller._events.add(const PlayButton());
            },
      icon: playState == null
          ? const Icon(Icons.play_arrow_rounded)
          : switch (playState) {
              PlayState.isPlaying => const Icon(Icons.stop_circle_rounded),
              PlayState.buffering => SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue.harmonizeWith(theme.colorScheme.primary),
                  ),
                ),
              PlayState.stopped => const Icon(Icons.play_arrow_rounded),
            },
    );
  }
}

class _VideoTime extends StatefulWidget {
  const _VideoTime({
    required super.key,
    required this.controller,
  });

  final _VideoControlsControllerImpl controller;

  @override
  State<_VideoTime> createState() => __VideoTimeState();
}

class __VideoTimeState extends State<_VideoTime> {
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
    final duration = widget.controller.duration;
    final progress = widget.controller.progress;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: duration == null || progress == null
            ? const SizedBox.shrink()
            : FittedBox(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _minutesSeconds(progress),
                        style: TextStyle(
                          color: theme.iconTheme.color?.withOpacity(0.6),
                        ),
                      ),
                      TextSpan(
                        text: "\n${_minutesSeconds(duration)}",
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

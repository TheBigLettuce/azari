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
    required this.seekTimeAnchor,
    required this.vertical,
  });

  final bool vertical;

  final VideoControlsControllerImpl videoControls;
  final GlobalKey<SeekTimeAnchorState> seekTimeAnchor;

  final VideoSettingsService db;

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

  VideoControlsControllerImpl get controls => widget.videoControls;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final children = [
      _PlayButton(
        key: playButtonKey,
        controller: controls,
      ),
      IconButton(
        style: const ButtonStyle(
          shape: WidgetStateProperty.fromMap({
            WidgetState.selected: CircleBorder(),
            WidgetState.any: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
          }),
        ),
        isSelected: videoSettings.volume != 0,
        onPressed: () {
          controls._events.add(const VolumeButton());
        },
        icon: videoSettings.volume == 0
            ? const Icon(Icons.volume_off_outlined)
            : const Icon(Icons.volume_up_outlined),
      ),
      IconButton(
        isSelected: videoSettings.looping,
        onPressed: () {
          controls._events.add(const LoopingButton());
        },
        icon: const Icon(Icons.loop_outlined),
      ),
      _VideoTime(
        key: videoTimeKey,
        controller: controls,
      ),
      IconButton.filledTonal(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            theme.colorScheme.surfaceContainerHigh.withValues(
              alpha: 0.6,
            ),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
          ),
        ),
        onPressed: () {
          controls._events.add(const FullscreenButton());
        },
        icon: const Icon(Icons.fullscreen_outlined),
      ),
    ];

    return Animate(
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
              width: widget.vertical ? null : 60,
              height: widget.vertical ? 60 : null,
              child: Card.filled(
                color: theme.colorScheme.surfaceContainerHigh
                    .withValues(alpha: 0.8),
                child: GestureDetector(
                  onPanStart: (details) {
                    widget.seekTimeAnchor.currentState
                        ?.updateDuration(0, false);
                  },
                  onPanUpdate: (details) {
                    widget.seekTimeAnchor.currentState?.updateDuration(
                      widget.vertical ? details.delta.dx : details.delta.dy,
                      widget.vertical,
                    );
                  },
                  onPanEnd: (details) {
                    widget.seekTimeAnchor.currentState?.finishUpdating();
                  },
                  child: widget.vertical
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SeekTimeAnchor extends StatefulWidget {
  const SeekTimeAnchor({
    required super.key,
    required this.bottomPadding,
    required this.videoControls,
  });

  final double bottomPadding;

  final VideoControlsControllerImpl videoControls;

  @override
  State<SeekTimeAnchor> createState() => SeekTimeAnchorState();
}

class SeekTimeAnchorState extends State<SeekTimeAnchor> {
  double? seekDuration;

  void updateDuration(double d, bool isVertical) {
    setState(() {
      if (seekDuration != null) {
        seekDuration =
            isVertical ? seekDuration! + (d * 0.2) : seekDuration! - (d * 0.2);
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

  final VideoControlsControllerImpl controller;

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

    return IconButton.filled(
      style: ButtonStyle(
        backgroundColor: WidgetStateColor.fromMap({
          WidgetState.selected: theme.colorScheme.primary.withValues(
            alpha: 0.8,
          ),
          WidgetState.any: theme.colorScheme.surfaceContainerLow.withValues(
            alpha: 0.6,
          ),
        }),
        shape: const WidgetStateProperty.fromMap({
          WidgetState.selected: CircleBorder(),
          WidgetState.any: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
        }),
      ),
      isSelected:
          playState == PlayState.isPlaying || playState == PlayState.buffering,
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

  final VideoControlsControllerImpl controller;

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
                          color: theme.iconTheme.color?.withValues(alpha: 0.6),
                        ),
                      ),
                      TextSpan(
                        text: "\n${_minutesSeconds(duration)}",
                        style: TextStyle(
                          color: theme.iconTheme.color?.withValues(alpha: 0.2),
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

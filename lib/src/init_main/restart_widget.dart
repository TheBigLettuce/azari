// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/init_main/build_theme.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:flutter/material.dart";

class RestartWidget extends StatefulWidget {
  const RestartWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget>
    with SingleTickerProviderStateMixin {
  Key key = UniqueKey();
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      value: 1,
      vsync: this,
      duration: Durations.extralong3,
      reverseDuration: Durations.long1,
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void restartApp() {
    controller.reverse().then((_) {
      setState(() {
        key = UniqueKey();
      });

      controller.forward();
    });
  }

  final _tween = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero);
  final _accelTween = CurveTween(curve: Easing.emphasizedAccelerate);
  final _decelTween = CurveTween(curve: Easing.emphasizedDecelerate);

  @override
  Widget build(BuildContext context) {
    final accentColor = const AppApi().accentColor;

    final d = buildTheme(Brightness.dark, accentColor);
    final l = buildTheme(Brightness.light, accentColor);

    return KeyedSubtree(
      key: key,
      child: ColoredBox(
        color: switch (MediaQuery.platformBrightnessOf(context)) {
          Brightness.dark => d.colorScheme.surface,
          Brightness.light => l.colorScheme.surface,
        },
        child: PinnedTagsHolder(
          pinnedTags: TagManagerService.safe()?.pinned,
          child: AnimatedBuilder(
            animation: controller.view,
            builder: (context, child) => Opacity(
              opacity: controller.value,
              child: FractionalTranslation(
                translation: _tween.evaluate(
                  switch (controller.status) {
                    AnimationStatus.completed ||
                    AnimationStatus.dismissed ||
                    AnimationStatus.forward =>
                      _decelTween.animate(controller.view),
                    AnimationStatus.reverse =>
                      _accelTween.animate(controller.view),
                  },
                ),
                child: child,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class TimeTickerStatistics extends StatefulWidget {
  const TimeTickerStatistics({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<TimeTickerStatistics> createState() => _TimeTickereStatisticsState();
}

class _TimeTickereStatisticsState extends State<TimeTickerStatistics> {
  static const int _maxSteps = 10;

  late final AppLifecycleListener listener;

  late final StreamSubscription<void>? timeTicker;
  final StreamController<Duration> timeListener = StreamController.broadcast();
  Duration currentDuration = Duration.zero;

  DateTime timeNow = DateTime.now();

  int stepsToSave = 0;
  bool inBackground = false;

  @override
  void initState() {
    super.initState();

    StatisticsDailyData? sts = StatisticsDailyService.safe()?.current;

    if (sts != null) {
      if (timeNow.day != sts.date.day ||
          timeNow.month != sts.date.month ||
          timeNow.year != sts.date.year) {
        sts = sts.copy(durationMillis: 0, swipedBoth: 0, date: timeNow)
          ..maybeSave();
      }

      currentDuration = Duration(milliseconds: sts.durationMillis);

      timeTicker =
          Stream<void>.periodic(const Duration(seconds: 1)).listen((event) {
        if (!inBackground) {
          bool switchDate = false;

          stepsToSave += 1;

          currentDuration = currentDuration + const Duration(seconds: 1);

          final nextTime = DateTime.now();

          if (timeNow.day != nextTime.day ||
              timeNow.month != nextTime.month ||
              timeNow.year != nextTime.year) {
            timeNow = nextTime;
            currentDuration = Duration.zero;
            switchDate = true;
          }

          timeListener.sink.add(currentDuration);

          if (stepsToSave >= _maxSteps || switchDate) {
            if (switchDate) {
              StatisticsDailyService.reset();
            } else {
              StatisticsDailyService.setDurationMillis(
                currentDuration.inMilliseconds,
              );
            }

            stepsToSave = 0;
          }

          if (switchDate) {
            setState(() {});
          }
        }
      });
    } else {
      timeTicker = null;
    }

    listener = AppLifecycleListener(
      onHide: () {
        inBackground = true;
      },
      onShow: () {
        inBackground = false;
      },
    );
  }

  Duration _c() => currentDuration;

  @override
  void dispose() {
    timeListener.close();
    timeTicker?.cancel();

    listener.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TimeSpentNotifier(
      timeNow,
      ticker: timeListener.stream,
      current: _c,
      child: widget.child,
    );
  }
}

// class GlobalProgressTab {
//   static GlobalProgressTab? maybeOf(BuildContext context) {
//     final widget = context.dependOnInheritedWidgetOfExactType<_ProgressTab>();

//     return widget?.tab;
//   }

//   static bool presentInScope(BuildContext context) {
//     final widget = context.dependOnInheritedWidgetOfExactType<_ProgressTab>();

//     return widget != null;
//   }

//   final Map<String, ValueNotifier<dynamic>> _notifiers = {};

//   void dispose() {
//     for (final e in _notifiers.values) {
//       e.dispose();
//     }

//     _notifiers.clear();
//   }

//   Widget inject(Widget child) => _ProgressTab(tab: this, child: child);

//   ValueNotifier<T> get<T>(String key, ValueNotifier<T> Function() factory) {
//     return _notifiers.putIfAbsent(key, factory) as ValueNotifier<T>;
//   }
// }

// class _ProgressTab extends InheritedWidget {
//   const _ProgressTab({
//     // super.key,
//     required this.tab,
//     required super.child,
//   });

//   final GlobalProgressTab tab;

//   @override
//   bool updateShouldNotify(_ProgressTab oldWidget) => tab != oldWidget.tab;
// }

class TimeSpentNotifier extends InheritedWidget {
  const TimeSpentNotifier(
    this._time, {
    super.key,
    required this.ticker,
    required this.current,
    required super.child,
  });

  final Stream<Duration> ticker;
  final Duration Function() current;
  final DateTime _time;

  static (Duration, Stream<Duration>) streamOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TimeSpentNotifier>();

    return (widget!.current(), widget.ticker);
  }

  @override
  bool updateShouldNotify(TimeSpentNotifier oldWidget) =>
      ticker != oldWidget.ticker ||
      current != oldWidget.current ||
      _time != oldWidget._time;
}

class PinnedTagsHolder extends StatefulWidget {
  const PinnedTagsHolder({
    super.key,
    required this.pinnedTags,
    required this.child,
  });

  final BooruTagging<Pinned>? pinnedTags;

  final Widget child;

  @override
  State<PinnedTagsHolder> createState() => _PinnedTagsHolderState();
}

class _PinnedTagsHolderState extends State<PinnedTagsHolder> {
  late final StreamSubscription<int>? countEvents;

  Map<String, void> pinnedTags = {};
  int count = 0;

  @override
  void initState() {
    super.initState();

    count = widget.pinnedTags?.count ?? 0;

    pinnedTags = (widget.pinnedTags?.get(-1) ?? []).fold({}, (map, e) {
      map[e.tag] = null;

      return map;
    });

    countEvents = widget.pinnedTags?.events.listen(
      (newCount) {
        if (newCount != count) {
          count = newCount;

          pinnedTags = (widget.pinnedTags?.get(-1) ?? []).fold({}, (map, e) {
            map[e.tag] = null;

            return map;
          });

          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    countEvents?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PinnedTagsProvider(
      pinnedTags: (map: pinnedTags, count: count),
      child: widget.child,
    );
  }
}

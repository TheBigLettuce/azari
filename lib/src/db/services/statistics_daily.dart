// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension StatisticsDailyDataExt on StatisticsDailyData {
  void maybeSave() => _currentDb.get<StatisticsDailyService>()?.add(this);
}

abstract interface class StatisticsDailyService implements ServiceMarker {
  StatisticsDailyData get current;

  void add(StatisticsDailyData data);

  StreamSubscription<StatisticsDailyData> watch(
    void Function(StatisticsDailyData d) f, [
    bool fire = false,
  ]);

  static void addSwipedBoth(int s) {
    final current = _currentDb.get<StatisticsDailyService>()?.current;

    current?.copy(swipedBoth: current.swipedBoth + s).maybeSave();
  }

  static void addDurationMillis(int d) {
    final current = _currentDb.get<StatisticsDailyService>()?.current;

    current?.copy(durationMillis: current.durationMillis + d).maybeSave();
  }

  static void setDurationMillis(int d) {
    final current = _currentDb.get<StatisticsDailyService>()?.current;

    current?.copy(durationMillis: d).maybeSave();
  }

  static void addDate(DateTime d) {
    final current = _currentDb.get<StatisticsDailyService>()?.current;

    current
        ?.copy(
          date: DateTime.fromMillisecondsSinceEpoch(
            current.date.millisecondsSinceEpoch + d.millisecondsSinceEpoch,
          ),
        )
        .maybeSave();
  }

  static void reset() {
    _currentDb
        .get<StatisticsDailyService>()
        ?.current
        .copy(
          durationMillis: 1,
          swipedBoth: 0,
          date: DateTime.now(),
        )
        .maybeSave();
  }
}

mixin StatisticsDailyWatcherMixin<S extends StatefulWidget> on State<S> {
  StatisticsDailyService get statisticsDailyService;

  StreamSubscription<StatisticsDailyData>? _statisticsDailyEvents;

  late StatisticsDailyData statisticsDaily;

  @override
  void initState() {
    super.initState();

    statisticsDaily = statisticsDailyService.current;

    _statisticsDailyEvents?.cancel();
    _statisticsDailyEvents = statisticsDailyService.watch((newSettings) {
      setState(() {
        statisticsDaily = newSettings;
      });
    });
  }

  @override
  void dispose() {
    _statisticsDailyEvents?.cancel();

    super.dispose();
  }
}

abstract class StatisticsDailyData {
  const StatisticsDailyData({
    required this.swipedBoth,
    required this.durationMillis,
    required this.date,
  });

  final int swipedBoth;
  final int durationMillis;

  final DateTime date;

  StatisticsDailyData copy({
    int? durationMillis,
    int? swipedBoth,
    DateTime? date,
  });

  StatisticsDailyData add({required int swipedBoth});
}

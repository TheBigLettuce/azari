// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension StatisticsBooruDataExt on StatisticsBooruData {
  void maybeSave() => _dbInstance.get<StatisticsBooruService>()?.add(this);
}

abstract interface class StatisticsBooruService implements ServiceMarker {
  static ImageViewStatistics? asImageViewStatistics() {
    final booru = _dbInstance.get<StatisticsBooruService>();
    final daily = _dbInstance.get<StatisticsDailyService>();
    if (booru == null || daily == null) {
      return null;
    }

    return ImageViewStatistics(
      swiped: () => booru.current.add(swiped: 1).maybeSave(),
      viewed: () {
        booru.current.add(viewed: 1).maybeSave();
        daily.current.add(swipedBoth: 1).maybeSave();
      },
    );
  }

  StatisticsBooruData get current;

  void add(StatisticsBooruData data);

  StreamSubscription<StatisticsBooruData> watch(
    void Function(StatisticsBooruData d) f, [
    bool fire = false,
  ]);

  static void addViewed(int v) {
    _dbInstance
        .get<StatisticsBooruService>()
        ?.current
        .add(viewed: v)
        .maybeSave();
  }

  static void addDownloaded(int d) {
    _dbInstance
        .get<StatisticsBooruService>()
        ?.current
        .add(downloaded: d)
        .maybeSave();
  }

  static void addSwiped(int s) {
    _dbInstance
        .get<StatisticsBooruService>()
        ?.current
        .add(swiped: s)
        .maybeSave();
  }

  static void addBooruSwitches(int b) {
    _dbInstance
        .get<StatisticsBooruService>()
        ?.current
        .add(booruSwitches: b)
        .maybeSave();
  }
}

mixin StatisticsBooruWatcherMixin<S extends StatefulWidget> on State<S> {
  StatisticsBooruService get statisticsBooruService;

  StreamSubscription<StatisticsBooruData>? _statisticsBooruEvents;

  late StatisticsBooruData statisticsBooru;

  @override
  void initState() {
    super.initState();

    statisticsBooru = statisticsBooruService.current;

    _statisticsBooruEvents?.cancel();
    _statisticsBooruEvents = statisticsBooruService.watch((newSettings) {
      setState(() {
        statisticsBooru = newSettings;
      });
    });
  }

  @override
  void dispose() {
    _statisticsBooruEvents?.cancel();

    super.dispose();
  }
}

abstract class StatisticsBooruData {
  const StatisticsBooruData({
    required this.booruSwitches,
    required this.downloaded,
    required this.swiped,
    required this.viewed,
  });

  final int viewed;
  final int downloaded;
  final int swiped;
  final int booruSwitches;

  StatisticsBooruData add({
    int? viewed,
    int? downloaded,
    int? swiped,
    int? booruSwitches,
  });
}

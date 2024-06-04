// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension StatisticsBooruDataExt on StatisticsBooruData {
  void save() => _currentDb.statisticsBooru.add(this);
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

abstract interface class StatisticsBooruService implements ServiceMarker {
  factory StatisticsBooruService.db() => _currentDb.statisticsBooru;

  static ImageViewStatistics asImageViewStatistics() {
    final db = _currentDb.statisticsBooru;
    final daily = _currentDb.statisticsDaily;

    return ImageViewStatistics(
      swiped: () => db.current.add(swiped: 1).save(),
      viewed: () {
        db.current.add(viewed: 1).save();
        daily.current.add(swipedBoth: 1).save();
      },
    );
  }

  StatisticsBooruData get current;

  void add(StatisticsBooruData data);

  StreamSubscription<StatisticsBooruData> watch(
    void Function(StatisticsBooruData) f, [
    bool fire = false,
  ]);
}

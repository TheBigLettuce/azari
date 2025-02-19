// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension StatisticsGalleryDataExt on StatisticsGalleryData {
  void maybeSave() => _currentDb.get<StatisticsGalleryService>()?.add(this);
}

abstract interface class StatisticsGalleryService implements ServiceMarker {
  static ImageViewStatistics? asImageViewStatistics() {
    final gallery = _currentDb.get<StatisticsGalleryService>();
    final daily = _currentDb.get<StatisticsDailyService>();
    if (gallery == null || daily == null) {
      return null;
    }

    return ImageViewStatistics(
      swiped: () => gallery.current.add(filesSwiped: 1).maybeSave(),
      viewed: () {
        gallery.current.add(viewedFiles: 1).maybeSave();
        daily.current.add(swipedBoth: 1).maybeSave();
      },
    );
  }

  StatisticsGalleryData get current;

  void add(StatisticsGalleryData data);

  StreamSubscription<StatisticsGalleryData> watch(
    void Function(StatisticsGalleryData d) f, [
    bool fire = false,
  ]);

  static void addViewedDirectories(int v) {
    _currentDb
        .get<StatisticsGalleryService>()
        ?.current
        .add(viewedDirectories: v)
        .maybeSave();
  }

  static void addViewedFiles(int v) {
    _currentDb
        .get<StatisticsGalleryService>()
        ?.current
        .add(viewedFiles: v)
        .maybeSave();
  }

  static void addFilesSwiped(int f) {
    _currentDb
        .get<StatisticsGalleryService>()
        ?.current
        .add(filesSwiped: f)
        .maybeSave();
  }

  static void addJoined(int j) {
    _currentDb
        .get<StatisticsGalleryService>()
        ?.current
        .add(joined: j)
        .maybeSave();
  }

  static void addSameFiltered(int s) {
    _currentDb
        .get<StatisticsGalleryService>()
        ?.current
        .add(sameFiltered: s)
        .maybeSave();
  }

  static void addDeleted(int d) {
    _currentDb
        .get<StatisticsGalleryService>()
        ?.current
        .add(deleted: d)
        .maybeSave();
  }

  static void addCopied(int c) {
    _currentDb
        .get<StatisticsGalleryService>()
        ?.current
        .add(copied: c)
        .maybeSave();
  }

  static void addMoved(int m) {
    _currentDb
        .get<StatisticsGalleryService>()
        ?.current
        .add(moved: m)
        .maybeSave();
  }
}

mixin StatisticsGalleryWatcherMixin<S extends StatefulWidget> on State<S> {
  StatisticsGalleryService get statisticsGalleryService;

  StreamSubscription<StatisticsGalleryData>? _statisticsGalleryEvents;

  late StatisticsGalleryData statisticsGallery;

  @override
  void initState() {
    super.initState();

    statisticsGallery = statisticsGalleryService.current;

    _statisticsGalleryEvents?.cancel();
    _statisticsGalleryEvents = statisticsGalleryService.watch((newSettings) {
      setState(() {
        statisticsGallery = newSettings;
      });
    });
  }

  @override
  void dispose() {
    _statisticsGalleryEvents?.cancel();

    super.dispose();
  }
}

abstract class StatisticsGalleryData {
  const StatisticsGalleryData({
    required this.copied,
    required this.deleted,
    required this.joined,
    required this.moved,
    required this.filesSwiped,
    required this.sameFiltered,
    required this.viewedDirectories,
    required this.viewedFiles,
  });

  final int viewedDirectories;
  final int viewedFiles;
  final int filesSwiped;
  final int joined;
  final int sameFiltered;
  final int deleted;
  final int copied;
  final int moved;

  StatisticsGalleryData add({
    int? viewedDirectories,
    int? viewedFiles,
    int? joined,
    int? filesSwiped,
    int? sameFiltered,
    int? deleted,
    int? copied,
    int? moved,
  });
}

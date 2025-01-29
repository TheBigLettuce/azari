// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension StatisticsGalleryDataExt on StatisticsGalleryData {
  void save() => _currentDb.statisticsGallery.add(this);
}

abstract interface class StatisticsGalleryService implements ServiceMarker {
  factory StatisticsGalleryService.db() => _currentDb.statisticsGallery;

  static ImageViewStatistics asImageViewStatistics() {
    final db = _currentDb.statisticsGallery;
    final daily = _currentDb.statisticsDaily;

    return ImageViewStatistics(
      swiped: () => db.current.add(filesSwiped: 1).save(),
      viewed: () {
        db.current.add(viewedFiles: 1).save();
        daily.current.add(swipedBoth: 1).save();
      },
    );
  }

  StatisticsGalleryData get current;

  void add(StatisticsGalleryData data);

  StreamSubscription<StatisticsGalleryData> watch(
    void Function(StatisticsGalleryData d) f, [
    bool fire = false,
  ]);
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

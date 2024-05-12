// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

class _UnsavableSettingsData extends GridSettingsData {
  const _UnsavableSettingsData({
    required super.aspectRatio,
    required super.columns,
    required super.layoutType,
    required super.hideName,
  });

  @override
  GridSettingsData copy({
    bool? hideName,
    GridAspectRatio? aspectRatio,
    GridColumn? columns,
    GridLayoutType? layoutType,
  }) =>
      _UnsavableSettingsData(
        aspectRatio: aspectRatio ?? this.aspectRatio,
        columns: columns ?? this.columns,
        layoutType: layoutType ?? this.layoutType,
        hideName: hideName ?? this.hideName,
      );
}

abstract class CancellableWatchableGridSettingsData
    implements WatchableGridSettingsData {
  void cancel();
}

class _InpersistentSettingsWatcher
    implements CancellableWatchableGridSettingsData {
  _InpersistentSettingsWatcher(this._current);

  final _events = StreamController<GridSettingsData>.broadcast();

  GridSettingsData _current;

  @override
  GridSettingsData get current => _current;

  @override
  set current(GridSettingsData d) {
    _current = d;

    _events.add(_current);
  }

  @override
  StreamSubscription<GridSettingsData> watch(
    void Function(GridSettingsData p1) f, [
    bool fire = false,
  ]) {
    return _events.stream.transform<GridSettingsData>(
      StreamTransformer((stream, cancelOnError) {
        final controller = StreamController<GridSettingsData>(sync: true);

        controller.onListen = () {
          final subscription = stream.listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
            cancelOnError: cancelOnError,
          );
          controller
            ..onPause = subscription.pause
            ..onResume = subscription.resume
            ..onCancel = subscription.cancel;
        };

        final l = controller.stream.listen(null);

        if (fire) {
          Timer.run(() {
            controller.add(current);
          });
        }

        return l;
      }),
    ).listen(f);
  }

  @override
  void cancel() => _events.close();
}

abstract class GridSettingsData {
  const GridSettingsData({
    required this.aspectRatio,
    required this.columns,
    required this.layoutType,
    required this.hideName,
  });

  static CancellableWatchableGridSettingsData noPersist({
    required bool hideName,
    required GridAspectRatio aspectRatio,
    required GridColumn columns,
    required GridLayoutType layoutType,
  }) =>
      _InpersistentSettingsWatcher(
        _UnsavableSettingsData(
          aspectRatio: aspectRatio,
          columns: columns,
          layoutType: layoutType,
          hideName: hideName,
        ),
      );

  final bool hideName;
  @enumerated
  final GridAspectRatio aspectRatio;
  @enumerated
  final GridColumn columns;

  @enumerated
  final GridLayoutType layoutType;

  GridSettingsData copy({
    bool? hideName,
    GridAspectRatio? aspectRatio,
    GridColumn? columns,
    GridLayoutType? layoutType,
  });
}

enum GridLayoutType {
  grid(),
  list(),
  gridQuilted(),
  gridMasonry();

  const GridLayoutType();

  String translatedString(BuildContext context) => switch (this) {
        GridLayoutType.grid =>
          AppLocalizations.of(context)!.enumGridLayoutTypeGrid,
        GridLayoutType.list =>
          AppLocalizations.of(context)!.enumGridLayoutTypeList,
        GridLayoutType.gridQuilted =>
          AppLocalizations.of(context)!.enumGridLayoutTypeGridQuilted,
        GridLayoutType.gridMasonry =>
          AppLocalizations.of(context)!.enumGridLayoutTypeGridMasonry,
      };

  // GridLayouter<T> layout<T extends CellBase>() => switch (this) {
  //       GridLayoutType.list => ListLayout<T>(),
  //       GridLayoutType.grid => GridLayout<T>(),
  //       GridLayoutType.gridQuilted => GridQuiltedLayout<T>(),
  //       GridLayoutType.gridMasonry => GridMasonryLayout<T>(),
  //     };
}

typedef GridSettingsWatcher = StreamSubscription<GridSettingsData> Function(
  void Function(GridSettingsData) f, [
  bool fire,
]);

abstract interface class WatchableGridSettingsData {
  GridSettingsData get current;
  set current(GridSettingsData d);

  StreamSubscription<GridSettingsData> watch(
    void Function(GridSettingsData) f, [
    bool fire = false,
  ]);
}

abstract interface class GridSettingsService {
  WatchableGridSettingsData get animeDiscovery;
  WatchableGridSettingsData get booru;
  WatchableGridSettingsData get directories;
  WatchableGridSettingsData get favoritePosts;
  WatchableGridSettingsData get files;
}

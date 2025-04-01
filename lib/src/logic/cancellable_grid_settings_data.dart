// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";

abstract class CancellableGridSettingsData<T extends GridSettingsType>
    implements GridSettingsData<T> {
  factory CancellableGridSettingsData.noPersist({
    required bool hideName,
    required GridAspectRatio aspectRatio,
    required GridColumn columns,
    required GridLayoutType layoutType,
  }) = _InpersistentSettingsWatcher;

  void cancel();
}

class _UnsavableSettingsData implements ShellConfigurationData {
  const _UnsavableSettingsData({
    required this.aspectRatio,
    required this.columns,
    required this.layoutType,
    required this.hideName,
  });

  @override
  final GridAspectRatio aspectRatio;

  @override
  final GridColumn columns;

  @override
  final bool hideName;

  @override
  final GridLayoutType layoutType;

  @override
  ShellConfigurationData copy({
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

class _InpersistentSettingsWatcher<T extends GridSettingsType>
    implements CancellableGridSettingsData<T> {
  _InpersistentSettingsWatcher({
    required bool hideName,
    required GridAspectRatio aspectRatio,
    required GridColumn columns,
    required GridLayoutType layoutType,
  }) : _current = _UnsavableSettingsData(
          aspectRatio: aspectRatio,
          columns: columns,
          layoutType: layoutType,
          hideName: hideName,
        );

  final _events = StreamController<ShellConfigurationData>.broadcast();

  ShellConfigurationData _current;

  @override
  ShellConfigurationData get current => _current;

  @override
  set current(ShellConfigurationData d) {
    _current = d;

    _events.add(_current);
  }

  @override
  StreamSubscription<ShellConfigurationData> watch(
    void Function(ShellConfigurationData p1) f, [
    bool fire = false,
  ]) {
    return _events.stream.transform<ShellConfigurationData>(
      StreamTransformer((stream, cancelOnError) {
        final controller = StreamController<ShellConfigurationData>(sync: true);

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

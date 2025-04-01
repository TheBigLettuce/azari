// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension VideoSettingsDataExt on VideoSettingsData {
  void maybeSave() => _dbInstance.get<VideoSettingsService>()?.add(this);
}

mixin class VideoSettingsService implements ServiceMarker {
  const VideoSettingsService();

  static bool get available => _instance != null;
  static VideoSettingsService? safe() => _instance;

  // ignore: unnecessary_late
  static late final VideoSettingsService? _instance =
      _dbInstance.get<VideoSettingsService>();

  VideoSettingsData get current => _instance!.current;

  void add(VideoSettingsData data) => _instance!.add(data);

  StreamSubscription<VideoSettingsData> watch(
    void Function(VideoSettingsData) f,
  ) =>
      _instance!.watch(f);
}

mixin VideoSettingsWatcherMixin<S extends StatefulWidget> on State<S> {
  StreamSubscription<VideoSettingsData>? _videoSettingsEvents;

  late VideoSettingsData? videoSettings;

  @override
  void initState() {
    super.initState();

    videoSettings = VideoSettingsService.safe()?.current;

    _videoSettingsEvents?.cancel();
    _videoSettingsEvents = VideoSettingsService.safe()?.watch((newSettings) {
      setState(() {
        videoSettings = newSettings;
      });
    });
  }

  @override
  void dispose() {
    _videoSettingsEvents?.cancel();

    super.dispose();
  }
}

abstract class VideoSettingsData {
  const VideoSettingsData({
    required this.looping,
    required this.volume,
  });

  final bool looping;
  final double volume;

  VideoSettingsData copy({bool? looping, double? volume});
}

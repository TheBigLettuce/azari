// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "download_manager.dart";

abstract interface class DownloadHandle implements CellBase, Thumbnailable {
  String get key;

  DownloadEntry get data;

  void cancel();

  StreamSubscription<double> watchProgress(PercentageCallback f);
}

class _DownloadEntry with DefaultBuildCellImpl implements DownloadHandle {
  _DownloadEntry({
    required this.data,
    required this.token,
    this.watcher,
  });

  StreamController<double>? watcher;

  double _downloadProgress = 0;
  double get downloadProgress => _downloadProgress;
  set downloadProgress(double i) {
    _downloadProgress = i;

    watcher?.sink.add(i);
  }

  @override
  final DownloadEntry data;

  @override
  String get key => data.url;

  final CancelToken token;

  @override
  void cancel() => token.cancel();

  @override
  CellStaticData description() => const CellStaticData();

  @override
  String alias(bool long) => data.name;

  @override
  ImageProvider<Object> thumbnail() =>
      CachedNetworkImageProvider(data.thumbUrl);

  @override
  Key uniqueKey() => ValueKey(data.url);

  @override
  StreamSubscription<double> watchProgress(PercentageCallback f) {
    watcher ??= StreamController.broadcast();

    return watcher!.stream.listen(f);
  }
}

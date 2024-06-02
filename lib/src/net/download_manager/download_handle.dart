// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "download_manager.dart";

abstract interface class DownloadHandle implements CellBase, Thumbnailable {
  String get key;

  DownloadEntry get data;

  void cancel();

  StreamSubscription<int> watchProgress(void Function(int c) f);
}

class _DownloadEntry implements DownloadHandle {
  _DownloadEntry({
    required this.data,
    required this.token,
    this.watcher,
  });

  StreamController<int>? watcher;

  int _downloadProgress = 0;
  int get downloadProgress => _downloadProgress;
  set downloadProgress(int i) {
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
  StreamSubscription<int> watchProgress(void Function(int c) f) {
    watcher ??= StreamController();

    return watcher!.stream.listen(f);
  }
}

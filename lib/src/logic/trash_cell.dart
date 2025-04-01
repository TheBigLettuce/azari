// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/segment_layout.dart";
import "package:flutter/widgets.dart";

class TrashCell implements AsyncCell<Directory> {
  TrashCell(this.galleryTrash);

  final _events = StreamController<Directory?>.broadcast();

  final GalleryTrash galleryTrash;

  bool get hasData => _currentData != null;
  Stream<Directory?> get stream => _events.stream;

  Directory? _currentData;
  Future<Directory?>? _trashFuture;

  void refresh() {
    if (_trashFuture != null) {
      _trashFuture?.ignore();
      _trashFuture = null;
    }

    _trashFuture = galleryTrash.thumb.then((e) {
      _currentData = e;

      _events.add(_currentData);
      return e;
    });
  }

  void dispose() {
    _trashFuture?.ignore();
    _events.close();
  }

  @override
  Key uniqueKey() => const ValueKey("trash");

  @override
  StreamSubscription<Directory?> watch(
    void Function(Directory? p1) f, [
    bool fire = false,
  ]) =>
      _events.stream.transform<Directory?>(
        StreamTransformer((input, cancelOnError) {
          final controller = StreamController<Directory?>(sync: true);
          controller.onListen = () {
            final subscription = input.listen(
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

          if (fire) {
            Timer.run(() {
              controller.add(_currentData);
            });
          }

          return controller.stream.listen(null);
        }),
      ).listen(f);
}

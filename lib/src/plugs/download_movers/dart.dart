// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:developer";
import "dart:io";
import "dart:isolate";

import "package:gallery/src/plugs/download_movers.dart";
import "package:logging/logging.dart";
import "package:path/path.dart" as path;

DartFileMover? _global;

class _FileMover {
  _FileMover._new();

  void move(MoveOp op) {
    try {
      Directory(path.joinAll([op.rootDir, op.targetDir])).createSync();
      File(op.source).copySync(
        path.joinAll([op.rootDir, op.targetDir, path.basename(op.source)]),
      );
      File(op.source).deleteSync();
    } catch (e, trace) {
      log("file mover", level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }
}

class DartFileMover implements DownloadMoverPlug {
  factory DartFileMover() {
    if (_global != null) {
      return _global!;
    } else {
      throw "mover is not initalized";
    }
  }

  DartFileMover._new(this._port);

  SendPort _port;

  @override
  void move(MoveOp op) {
    _port.send(op);
  }
}

Future<DartFileMover> initalizeDartMover() {
  if (_global != null) {
    return Future.value(_global);
  }

  return Future(() async {
    final recv = ReceivePort();

    await Isolate.spawn(_startMover, recv.sendPort);

    final send = await recv.first as SendPort;

    _global = DartFileMover._new(send);

    return _global!;
  });
}

Future<void> _startMover(SendPort message) async {
  final recv = ReceivePort();
  message.send(recv.sendPort);

  final mover = _FileMover._new();

  await for (final op in recv) {
    mover.move(op as MoveOp);
  }
}

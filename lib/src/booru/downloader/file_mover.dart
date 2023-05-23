import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

FileMover? _global;

class _FileMover {
  void move(MoveOp op) {
    try {
      Directory(path.joinAll([op.rootDir, op.targetDir])).createSync();
      File(op.source).copySync(
          path.joinAll([op.rootDir, op.targetDir, path.basename(op.source)]));
      File(op.source).deleteSync();
    } catch (e, trace) {
      log("file mover", level: Level.SEVERE.value, error: e, stackTrace: trace);
    }
  }

  _FileMover._new();
}

class FileMover {
  SendPort _port;
  Isolate _moverIsolate;

  FileMover._new(this._port, this._moverIsolate);

  void move(MoveOp op) {
    _port.send(op);
  }

  factory FileMover() {
    if (_global != null) {
      return _global!;
    } else {
      throw "mover is not initalized";
    }
  }
}

Future<FileMover> initalizeMover() {
  if (_global != null) {
    return Future.value(_global);
  }

  return Future(() async {
    ReceivePort recv = ReceivePort();
    var isolate = await Isolate.spawn(_startMover, recv.sendPort);

    SendPort send = await recv.first;

    _global = FileMover._new(send, isolate);

    return _global!;
  });
}

class MoveOp {
  String source;
  String rootDir;
  String targetDir;

  MoveOp(
      {required this.source, required this.rootDir, required this.targetDir});
}

void _startMover(SendPort message) async {
  ReceivePort recv = ReceivePort();
  message.send(recv.sendPort);

  var mover = _FileMover._new();

  await for (var op in recv) {
    mover.move(op);
  }
}

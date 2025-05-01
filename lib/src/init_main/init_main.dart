// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:developer";
import "dart:ui" as ui;

import "package:azari/src/services/services.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:logging/logging.dart";

Future<void> initMain(AppInstanceType appType) async {
  _initLogger();

  WidgetsFlutterBinding.ensureInitialized();

  _changeExceptionErrorColors();

  await initServices(appType);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

Future<void> wrapZone(Future<void> Function() fn) async =>
    await runZonedGuarded<Future<void>>(
      () async => await fn(),
      (error, stackTrace) {
        AlertService.safe()?.add(_ExcMessage(error, stackTrace));
      },
    );

void _initLogger() {
  if (kReleaseMode) {
    return;
  }

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) {
    AlertService.safe()?.add(_LogMessage(r));

    log(
      r.message,
      time: r.time,
      sequenceNumber: r.sequenceNumber,
      level: r.level.value,
      name: r.loggerName,
      zone: r.zone,
      stackTrace: r.stackTrace,
      error: r.error,
    );
  });
}

void _changeExceptionErrorColors() {
  RenderErrorBox.backgroundColor = Colors.blue.shade800;
  RenderErrorBox.textStyle = ui.TextStyle(color: Colors.white70);
}

class _LogMessage implements AlertData {
  _LogMessage(this.r);

  @override
  final (VoidCallback, Icon)? onPressed = null;

  final LogRecord r;

  @override
  String title() {
    return "Log: ${r.message}";
  }

  @override
  String? expandedInfo() {
    return r.stackTrace?.toString();
  }
}

class _ExcMessage implements AlertData {
  _ExcMessage(this.e, this.trace);

  final Object e;
  final StackTrace trace;

  @override
  (VoidCallback, Icon)? get onPressed => null;

  @override
  String title() => "Exception: $e";

  @override
  String? expandedInfo() => trace.toString();
}

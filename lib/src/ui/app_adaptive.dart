// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/ui/cupertino/app.dart";
import "package:azari/src/ui/material/app.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class AppAdaptive extends StatelessWidget {
  const AppAdaptive({
    super.key,
    required this.color,
    required this.notificationStream,
  });

  final Color color;
  final Stream<NotificationRouteEvent> notificationStream;

  @override
  Widget build(BuildContext context) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows =>
        AppMaterial(color: color, notificationStream: notificationStream),
      TargetPlatform.macOS ||
      TargetPlatform.iOS =>
        AppCupertino(color: color, notificationStream: notificationStream),
    };
  }
}

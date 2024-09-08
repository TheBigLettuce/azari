// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:io";

import "package:azari/src/plugs/generated/platform_api.g.dart";
import "package:azari/src/plugs/notifications.dart";
import "package:azari/src/plugs/notifications/android.dart";
import "package:azari/src/plugs/notifications/dummy.dart";
import "package:azari/src/plugs/notifications/kde.dart";

NotificationPlug getApi() {
  if (Platform.isLinux) {
    return KDENotifications();
  } else if (Platform.isAndroid) {
    return AndroidNotifications();
  } else {
    return const DummyNotifications();
  }
}

Future<NotificationPressedImpl> init(
  StreamController<NotificationRouteEvent> stream,
) =>
    Future.value(NotificationPressedImpl(stream.sink));

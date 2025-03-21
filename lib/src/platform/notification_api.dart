// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/platform/generated/platform_api.g.dart";
import "package:azari/src/platform/notifications/io.dart"
    if (dart.library.html) "package:azari/src/platform/notifications/web.dart";

export "package:azari/src/platform/generated/platform_api.g.dart"
    show NotificationChannel, NotificationGroup, NotificationRouteEvent;

abstract class NotificationApi {
  factory NotificationApi() {
    if (_api != null) {
      return _api!;
    }

    return _api = getApi();
  }

  static NotificationApi? _api;

  static const savingTagsId = -10;
  static const savingThumbId = -11;
  static const redownloadFilesId = -12;

  Future<NotificationHandle> show({
    required int id,
    required String title,
    required NotificationChannel channel,
    required NotificationGroup group,
    String? body,
    String? payload,
  });
}

abstract class NotificationHandle {
  void setTotal(int t);
  void update(int progress, [String? str]);
  void done();
  void error(String s);
}

Future<void> initNotifications(
  Sink<NotificationRouteEvent> sink,
) async {
  OnNotificationPressed.setUp(await init(sink));
}

class NotificationPressedImpl implements OnNotificationPressed {
  const NotificationPressedImpl(this.sink);

  final Sink<NotificationRouteEvent> sink;

  @override
  void onPressed(NotificationRouteEvent r) {
    sink.add(r);
  }
}

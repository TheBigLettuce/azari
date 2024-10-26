// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/platform/notification_api.dart";

class DummyProgress implements NotificationHandle {
  const DummyProgress();

  @override
  void setTotal(int t) {}
  @override
  void update(int progress, [String? str]) {}
  @override
  void done() {}
  @override
  void error(String s) {}
}

class DummyNotifications implements NotificationApi {
  const DummyNotifications();

  @override
  Future<NotificationHandle> show({
    required int id,
    required String title,
    required NotificationChannel channel,
    required NotificationGroup group,
    String? body,
    String? payload,
  }) =>
      Future.value(const DummyProgress());
}

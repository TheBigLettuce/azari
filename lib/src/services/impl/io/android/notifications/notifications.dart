// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/platform/platform_api.g.dart" as platform;
import "package:azari/src/services/impl/io.dart";
import "package:azari/src/services/services.dart";

const _max = 12;

class NotificationsImpl implements NotificationApi {
  @override
  Future<NotificationHandle> show({
    required NotificationChannelId id,
    required String title,
    required NotificationChannel channel,
    required NotificationGroup group,
    String? body,
    String? payload,
  }) =>
      Future.value(
        AndroidNotificationHandle(
          group: group,
          id: id,
          title: title,
          channel: channel,
          body: body,
          payload: payload,
        ),
      );
}

class AndroidNotificationHandle implements NotificationHandle {
  AndroidNotificationHandle({
    required this.group,
    required this.id,
    required this.title,
    required this.channel,
    required this.body,
    required this.payload,
  });

  final NotificationChannelId id;

  final String title;
  final String? body;
  final String? payload;

  final NotificationChannel channel;
  final NotificationGroup group;

  int total = 0;
  int _step = 0;
  int _currentSteps = 0;

  final api = platform.NotificationsApi();

  void _showNotification(int progress, String name) {
    api.post(
      channel,
      platform.Notification(
        id: (id as AndroidNotificationChannelId).id,
        title: name,
        body: body,
        group: group,
        maxProgress: total,
        currentProgress: progress,
        indeterminate: total == -1,
        payload: payload,
      ),
    );
  }

  @override
  void update(int progress, [String? str]) {
    if (str != null) {
      _showNotification(progress, str);
    } else {
      if (progress > (_currentSteps == 0 ? _step : _step * _currentSteps)) {
        _currentSteps++;

        _showNotification(progress, title);
      }
    }
  }

  @override
  void error(String s) {
    api.cancel((id as AndroidNotificationChannelId).id);
  }

  @override
  void done() {
    api.cancel((id as AndroidNotificationChannelId).id);
  }

  @override
  void setTotal(int t) {
    if (total == 0) {
      total = t;
      _step = (total / _max).floor();
    }
  }
}

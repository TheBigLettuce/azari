// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/plugs/notifications.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";

const _max = 12;

class AndroidProgress implements NotificationProgress {
  AndroidProgress({
    required this.group,
    required this.id,
    required this.name,
    required this.channelName,
    required this.body,
    required this.payload,
  });

  final String group;
  final int id;
  final String name;
  final String channelName;
  final String? body;
  final String? payload;

  int total = 0;
  int _step = 0;
  int _currentSteps = 0;

  void _showNotification(int progress, String name) {
    FlutterLocalNotificationsPlugin().show(
      id,
      name,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelName.toLowerCase(),
          channelName,
          groupKey: group,
          ongoing: true,
          playSound: false,
          enableVibration: false,
          importance: Importance.low,
          category: AndroidNotificationCategory.progress,
          maxProgress: total,
          progress: progress,
          visibility: NotificationVisibility.private,
          indeterminate: total == -1,
          showProgress: true,
        ),
      ),
      payload: payload,
    );
  }

  @override
  void update(int progress, [String? str]) {
    if (str != null) {
      _showNotification(progress, str);
    } else {
      if (progress > (_currentSteps == 0 ? _step : _step * _currentSteps)) {
        _currentSteps++;

        _showNotification(progress, name);
      }
    }
  }

  @override
  void error(String s) {
    FlutterLocalNotificationsPlugin().cancel(id);
  }

  @override
  void done() {
    FlutterLocalNotificationsPlugin().cancel(id);
  }

  @override
  void setTotal(int t) {
    if (total == 0) {
      total = t;
      _step = (total / _max).floor();
    }
  }
}

class AndroidNotifications implements NotificationPlug {
  @override
  Future<NotificationProgress> newProgress(
    String name,
    int id,
    String group,
    String channelName, {
    String? body,
    String? payload,
  }) =>
      Future.value(
        AndroidProgress(
          group: group,
          id: id,
          name: name,
          channelName: channelName,
          body: body,
          payload: payload,
        ),
      );
}

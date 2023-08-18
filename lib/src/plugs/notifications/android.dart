// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery/src/plugs/notifications.dart';

const _max = 12;

class AndroidProgress implements NotificationProgress {
  int total = 0;
  int _step = 0;
  int _currentSteps = 0;
  String group;
  int id;
  String name;

  _showNotification(int progress) {
    FlutterLocalNotificationsPlugin().show(
      id,
      group,
      name,
      NotificationDetails(
        android: AndroidNotificationDetails("download", "Dowloader",
            groupKey: group,
            ongoing: true,
            playSound: false,
            enableLights: false,
            enableVibration: false,
            category: AndroidNotificationCategory.progress,
            maxProgress: total,
            progress: progress,
            visibility: NotificationVisibility.private,
            indeterminate: total == -1,
            showProgress: true),
      ),
    );
  }

  @override
  void update(int progress) {
    if (progress > (_currentSteps == 0 ? _step : _step * _currentSteps)) {
      _currentSteps++;

      _showNotification(progress);
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

  AndroidProgress({required this.group, required this.id, required this.name});
}

class AndroidNotifications implements NotificationPlug {
  @override
  Future<NotificationProgress> newProgress(String name, int id, String group) =>
      Future.value(AndroidProgress(group: group, id: id, name: name));
}

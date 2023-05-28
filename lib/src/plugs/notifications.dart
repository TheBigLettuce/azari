// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:gallery/src/plugs/notifications/android.dart';
import 'package:gallery/src/plugs/notifications/dummy.dart';
import 'package:gallery/src/plugs/notifications/kde.dart';

abstract class NotificationProgress {
  void setTotal(int t);
  void update(int progress);
  void done();
  void error(String s);
}

abstract class NotificationPlug {
  Future<NotificationProgress> newProgress(String name, int id, String group);
}

NotificationPlug chooseNotificationPlug() {
  if (Platform.isLinux) {
    return KDENotifications();
  } else if (Platform.isAndroid) {
    return AndroidNotifications();
  } else {
    return DummyNotifications();
  }
}

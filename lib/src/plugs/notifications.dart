// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/plugs/notifications/dummy_.dart"
    if (dart.library.io) "package:gallery/src/plugs/notifications/io.dart"
    if (dart.library.html) "package:gallery/src/plugs/notifications/web.dart";

abstract class NotificationProgress {
  void setTotal(int t);
  void update(int progress, [String? str]);
  void done();
  void error(String s);
}

abstract class NotificationPlug {
  Future<NotificationProgress> newProgress(
    String name,
    int id,
    String group,
    String channelName,
  );
}

NotificationPlug chooseNotificationPlug() => getApi();

Future<void> initNotifications() => init();

const savingTagsNotifId = -10;
const savingThumbNotifId = -11;

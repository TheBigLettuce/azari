// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dbus/dbus.dart';
import 'package:gallery/src/plugs/notifications.dart';
import 'package:gallery/src/plugs/notifications/dummy.dart';

import '../../../dbus/job_view.g.dart';
import '../../../dbus/job_view_server.g.dart';

class KDENotificationProgress extends NotificationProgress {
  final OrgKdeJobViewV2 _job;
  int total = 0;

  KDENotificationProgress(OrgKdeJobViewV2 job) : _job = job;

  @override
  void setTotal(int t) {
    if (total == 0) {
      total = t;
      _job.callsetTotalAmount(t, "bytes");
    }
  }

  @override
  void update(int progress, [String? str]) {
    _job.callsetProcessedAmount(progress, "bytes");
    _job.callsetPercent((progress / total * 100).toInt());
  }

  @override
  void done() {
    _job.callterminate("");
  }

  @override
  void error(String s) {
    _job.callterminate(s);
  }
}

class KDENotifications implements NotificationPlug {
  final DBusClient _client = DBusClient.session();

  @override
  Future<NotificationProgress> newProgress(String name, _, __, ___) async {
    try {
      final object = OrgKdeJobViewServer(
          _client, "org.kde.kuiserver", DBusObjectPath("/JobViewServer"));
      final id = await object.callrequestView("Ācārya", "", 0);

      final notif = OrgKdeJobViewV2(_client, "org.kde.kuiserver", id);

      notif.callsetInfoMessage(name);

      return Future.value(KDENotificationProgress(notif));
    } catch (_) {
      return DummyProgress();
    }
  }
}

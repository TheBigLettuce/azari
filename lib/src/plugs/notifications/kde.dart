// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/dbus/job_view.g.dart";
import "package:azari/dbus/job_view_server.g.dart";
import "package:azari/src/plugs/notifications.dart";
import "package:azari/src/plugs/notifications/dummy.dart";
import "package:dbus/dbus.dart";

class KDENotificationProgress extends NotificationProgress {
  KDENotificationProgress(OrgKdeJobViewV2 job) : _job = job;
  final OrgKdeJobViewV2 _job;
  int total = 0;

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
  Future<NotificationProgress> newProgress(
    String name,
    _,
    __,
    ___, {
    String? body,
  }) async {
    try {
      final object = OrgKdeJobViewServer(
        _client,
        "org.kde.kuiserver",
        DBusObjectPath("/JobViewServer"),
      );
      final id = await object.callrequestView("Ācārya", "", 0);

      final notif = OrgKdeJobViewV2(_client, "org.kde.kuiserver", id);

      await notif.callsetInfoMessage(name);
      if (body != null) {
        await notif.callsetDescriptionField(0, "", body);
      }

      return Future.value(KDENotificationProgress(notif));
    } catch (_) {
      return const DummyProgress();
    }
  }
}

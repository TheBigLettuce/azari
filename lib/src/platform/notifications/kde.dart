// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/dbus/job_view.g.dart";
import "package:azari/dbus/job_view_server.g.dart";
import "package:azari/src/platform/notification_api.dart";
import "package:azari/src/platform/notifications/dummy.dart";
import "package:dbus/dbus.dart";

class KDENotificationProgress extends NotificationHandle {
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

class KDENotifications implements NotificationApi {
  final DBusClient _client = DBusClient.session();

  @override
  Future<NotificationHandle> show({
    required int id,
    required String title,
    required NotificationChannel channel,
    required NotificationGroup group,
    String? body,
    String? payload,
  }) async {
    try {
      final object = OrgKdeJobViewServer(
        _client,
        "org.kde.kuiserver",
        DBusObjectPath("/JobViewServer"),
      );
      final id = await object.callrequestView("Azari", "", 0);

      final notif = OrgKdeJobViewV2(_client, "org.kde.kuiserver", id);

      await notif.callsetInfoMessage(title);
      if (body != null) {
        await notif.callsetDescriptionField(0, "", body);
      }

      return Future.value(KDENotificationProgress(notif));
    } catch (_) {
      return const DummyProgress();
    }
  }
}

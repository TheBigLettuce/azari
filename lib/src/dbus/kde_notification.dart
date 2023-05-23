import 'package:dbus/dbus.dart';

import 'job_view.g.dart';
import 'job_view_server.g.dart';

abstract class LinuxNotification {
  void setTotal(int t);
  void update(int progress);
  void done();
  void error(String s);
}

class _DummyNotification extends LinuxNotification {
  @override
  void setTotal(int t) {}
  @override
  void update(int progress) {}
  @override
  void done() {}
  @override
  void error(String s) {}
}

class KDENotificationProgress extends LinuxNotification {
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
  void update(int progress) {
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

class KDENotification {
  final DBusClient _client = DBusClient.session();

  Future<LinuxNotification> createJob(String name) async {
    try {
      var object = OrgKdeJobViewServer(
          _client, "org.kde.kuiserver", DBusObjectPath("/JobViewServer"));
      var id = await object.callrequestView("Ācārya", "", 0);

      var notif =
          OrgKdeJobViewV2(_client, "org.kde.kuiserver", DBusObjectPath(id));

      notif.callsetInfoMessage(name);

      return Future.value(KDENotificationProgress(notif));
    } catch (_) {
      return _DummyNotification();
    }
  }
}

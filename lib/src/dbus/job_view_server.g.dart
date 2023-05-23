// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object kf5_org.kde.JobViewServer.xml

import 'package:dbus/dbus.dart';

class OrgKdeJobViewServer extends DBusRemoteObject {
  OrgKdeJobViewServer(
      DBusClient client, String destination, DBusObjectPath path)
      : super(client, name: destination, path: path);

  /// Invokes org.kde.JobViewServer.requestView()
  Future<String> callrequestView(
      String appName, String appIconName, int capabilities,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.kde.JobViewServer', 'requestView',
        [DBusString(appName), DBusString(appIconName), DBusInt32(capabilities)],
        replySignature: DBusSignature('o'),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPath().value;
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object /usr/share/dbus-1/interfaces/kf5_org.kde.JobViewServer.xml

import 'dart:io';
import 'package:dbus/dbus.dart';

class OrgKdeJobViewServer extends DBusRemoteObject {
  OrgKdeJobViewServer(
      DBusClient client, String destination, DBusObjectPath path)
      : super(client, name: destination, path: path);

  /// Invokes org.kde.JobViewServer.requestView()
  Future<DBusObjectPath> callrequestView(
      String appName, String appIconName, int capabilities,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.kde.JobViewServer', 'requestView',
        [DBusString(appName), DBusString(appIconName), DBusInt32(capabilities)],
        replySignature: DBusSignature('o'),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asObjectPath();
  }
}

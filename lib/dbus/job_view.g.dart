// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// This file was generated using the following command and may be overwritten.
// dart-dbus generate-remote-object /usr/share/dbus-1/interfaces/kf5_org.kde.JobView.xml

import 'dart:io';
import 'package:dbus/dbus.dart';

/// Signal data for org.kde.JobViewV2.suspendRequested.
class OrgKdeJobViewV2suspendRequested extends DBusSignal {
  OrgKdeJobViewV2suspendRequested(DBusSignal signal)
      : super(
            sender: signal.sender,
            path: signal.path,
            interface: signal.interface,
            name: signal.name,
            values: signal.values);
}

/// Signal data for org.kde.JobViewV2.resumeRequested.
class OrgKdeJobViewV2resumeRequested extends DBusSignal {
  OrgKdeJobViewV2resumeRequested(DBusSignal signal)
      : super(
            sender: signal.sender,
            path: signal.path,
            interface: signal.interface,
            name: signal.name,
            values: signal.values);
}

/// Signal data for org.kde.JobViewV2.cancelRequested.
class OrgKdeJobViewV2cancelRequested extends DBusSignal {
  OrgKdeJobViewV2cancelRequested(DBusSignal signal)
      : super(
            sender: signal.sender,
            path: signal.path,
            interface: signal.interface,
            name: signal.name,
            values: signal.values);
}

class OrgKdeJobViewV2 extends DBusRemoteObject {
  /// Stream of org.kde.JobViewV2.suspendRequested signals.
  late final Stream<OrgKdeJobViewV2suspendRequested> suspendRequested;

  /// Stream of org.kde.JobViewV2.resumeRequested signals.
  late final Stream<OrgKdeJobViewV2resumeRequested> resumeRequested;

  /// Stream of org.kde.JobViewV2.cancelRequested signals.
  late final Stream<OrgKdeJobViewV2cancelRequested> cancelRequested;

  OrgKdeJobViewV2(DBusClient client, String destination, DBusObjectPath path)
      : super(client, name: destination, path: path) {
    suspendRequested = DBusRemoteObjectSignalStream(
            object: this,
            interface: 'org.kde.JobViewV2',
            name: 'suspendRequested',
            signature: DBusSignature(''))
        .asBroadcastStream()
        .map((signal) => OrgKdeJobViewV2suspendRequested(signal));

    resumeRequested = DBusRemoteObjectSignalStream(
            object: this,
            interface: 'org.kde.JobViewV2',
            name: 'resumeRequested',
            signature: DBusSignature(''))
        .asBroadcastStream()
        .map((signal) => OrgKdeJobViewV2resumeRequested(signal));

    cancelRequested = DBusRemoteObjectSignalStream(
            object: this,
            interface: 'org.kde.JobViewV2',
            name: 'cancelRequested',
            signature: DBusSignature(''))
        .asBroadcastStream()
        .map((signal) => OrgKdeJobViewV2cancelRequested(signal));
  }

  /// Invokes org.kde.JobViewV2.terminate()
  Future<void> callterminate(String errorMessage,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod(
        'org.kde.JobViewV2', 'terminate', [DBusString(errorMessage)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.JobViewV2.setSuspended()
  Future<void> callsetSuspended(bool suspended,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod(
        'org.kde.JobViewV2', 'setSuspended', [DBusBoolean(suspended)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.JobViewV2.setTotalAmount()
  Future<void> callsetTotalAmount(int amount, String unit,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.kde.JobViewV2', 'setTotalAmount',
        [DBusUint64(amount), DBusString(unit)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.JobViewV2.setProcessedAmount()
  Future<void> callsetProcessedAmount(int amount, String unit,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.kde.JobViewV2', 'setProcessedAmount',
        [DBusUint64(amount), DBusString(unit)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.JobViewV2.setPercent()
  Future<void> callsetPercent(int percent,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.kde.JobViewV2', 'setPercent', [DBusUint32(percent)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.JobViewV2.setSpeed()
  Future<void> callsetSpeed(int bytesPerSecond,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod(
        'org.kde.JobViewV2', 'setSpeed', [DBusUint64(bytesPerSecond)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.JobViewV2.setInfoMessage()
  Future<void> callsetInfoMessage(String message,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod(
        'org.kde.JobViewV2', 'setInfoMessage', [DBusString(message)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.JobViewV2.setDescriptionField()
  Future<bool> callsetDescriptionField(int number, String name, String value,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.kde.JobViewV2', 'setDescriptionField',
        [DBusUint32(number), DBusString(name), DBusString(value)],
        replySignature: DBusSignature('b'),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
    return result.returnValues[0].asBoolean();
  }

  /// Invokes org.kde.JobViewV2.clearDescriptionField()
  Future<void> callclearDescriptionField(int number,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod(
        'org.kde.JobViewV2', 'clearDescriptionField', [DBusUint32(number)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.JobViewV2.setDestUrl()
  Future<void> callsetDestUrl(DBusValue destUrl,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.kde.JobViewV2', 'setDestUrl', [DBusVariant(destUrl)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }

  /// Invokes org.kde.JobViewV2.setError()
  Future<void> callsetError(int errorCode,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    await callMethod('org.kde.JobViewV2', 'setError', [DBusUint32(errorCode)],
        replySignature: DBusSignature(''),
        noReplyExpected: true,
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
  }
}

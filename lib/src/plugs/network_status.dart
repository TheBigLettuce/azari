// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/plugs/network_status/dummy.dart"
    if (dart.library.io) "package:gallery/src/plugs/network_status/io.dart"
    if (dart.library.html) "package:gallery/src/plugs/network_status/web.dart";

late final NetworkStatus _status;

class NetworkStatus {
  NetworkStatus(this.hasInternet);

  bool hasInternet;
  void Function()? notify;

  static NetworkStatus get g => _status;
}

Future<void> initalizeNetworkStatus() async {
  _status = NetworkStatus(await register());

  return;
}

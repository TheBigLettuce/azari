// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/interfaces/refreshing_status_interface.dart';

class PagingContainer {
  PagingContainer();

  int page = 0;
  double scrollPos = 0;

  Future<int>? status;
  final Map<void Function(int?, bool), Null> listeners = {};

  late final RefreshingStatusInterface refreshingInterface =
      RefreshingStatusInterface(
    isRefreshing: () => status != null,
    save: (s) {
      status?.ignore();
      status = s;

      status?.then((value) {
        for (final f in listeners.keys) {
          f(value, false);
        }
      }).onError((error, stackTrace) {
        for (final f in listeners.keys) {
          f(null, false);
        }
      }).whenComplete(() => status = null);
    },
    register: (f) {
      if (status != null) {
        f(null, true);
      }

      listeners[f] = null;
    },
    unregister: (f) => listeners.remove(f),
    reset: () {
      status?.ignore();
      status = null;
    },
  );

  void updateScrollPos(double pos, {double? infoPos, int? selectedCell}) {
    scrollPos = pos;
  }
}

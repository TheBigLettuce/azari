// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../home.dart';

mixin _MainGridRefreshingInterfaceMixin {
  Future<int>? status;
  final Map<void Function(int?, bool), Null> _listeners = {};

  late final refreshInterface = RefreshingStatusInterface(
    isRefreshing: () => status != null,
    save: (s) {
      status?.ignore();
      status = s;

      status?.then((value) {
        for (final f in _listeners.keys) {
          f(value, false);
        }

        // isRefreshing = false;
      }).onError((error, stackTrace) {
        for (final f in _listeners.keys) {
          f(null, false);
        }
      }).whenComplete(() => status = null);
    },
    register: (f) {
      if (status != null) {
        f(null, true);
      }

      _listeners[f] = null;
    },
    unregister: (f) => _listeners.remove(f),
    reset: () {
      status?.ignore();
      status = null;
    },
  );
}

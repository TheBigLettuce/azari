// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:isolate';

import 'control_message.dart';
import 'data_transformer.dart';
import 'loader_state_controller.dart';

/// Load data in a background isolate.
/// Depends on the ability of writing to the source on a different Isolate.
abstract interface class BackgroundDataLoader<T> {
  /// Isolate associated with the loader.
  /// [listenStatus] should be called before accessing [isolate].
  Isolate get isolate;

  Future<void> init();

  /// Begin listening for the events in the source.
  /// After the call to [listenStatus] complete, [isolate], [send]
  /// and [dispose] become available.
  /// Trying to access [listenStatus], [send] or [dispose] before [listenStatus]'s future
  /// complete is undefined behaviour.
  void listenStatus(void Function(int) f);

  /// Return the single piece of data.
  /// This is used in the widget builders.
  T? getSingle(int token);

  /// Send the data for the insertion.
  /// [l] should be immutable, otherwise there is not much
  /// benefit in using [BackgroundDataLoader].
  /// [listenStatus] should be called before calling [send].
  void send(ControlMessage m);

  /// Shutdown the loader. After the call to [dispose],
  /// the instance is invalid and should not be used.
  /// [listenStatus] should be called before calling [dispose].
  void dispose();

  LoaderStateController get state;

  DataTransformer? get transformer;

  const BackgroundDataLoader();
}

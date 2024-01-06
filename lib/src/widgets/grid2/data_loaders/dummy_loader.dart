// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:isolate';

import 'dummy_controller.dart';
import '../../../interfaces/background_data_loader/background_data_loader.dart';
import '../../../interfaces/background_data_loader/control_message.dart';
import '../../../interfaces/background_data_loader/data_transformer.dart';
import '../../../interfaces/background_data_loader/loader_state_controller.dart';

class DummyBackgroundLoader<T, J> implements BackgroundDataLoader<T> {
  const DummyBackgroundLoader();

  @override
  void dispose() {}

  @override
  T? getSingle(int token) => null;

  @override
  Isolate get isolate => throw UnimplementedError();

  @override
  void listenStatus(void Function(int p1) f) {}

  @override
  Future<void> init() => Future.value();

  @override
  void send(ControlMessage m) {}

  @override
  LoaderStateController get state => const DummyLoaderStateController();

  @override
  DataTransformer? get transformer => null;
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:typed_data';

import 'package:meta/meta.dart';

@immutable
sealed class ControlMessage {
  const ControlMessage();
}

@immutable
class Reset extends ControlMessage {
  final bool silent;

  const Reset([this.silent = false]);
}

@immutable
class Data<T> extends ControlMessage {
  final List<T> l;
  final bool end;

  const Data(this.l, {this.end = false});
}

@immutable
class Poll extends ControlMessage {
  const Poll();
}

@immutable
class Binary extends ControlMessage {
  final int type;
  final ByteData data;

  const Binary(this.data, {required this.type});
}

@immutable
class ChangeContext extends ControlMessage {
  final int contextStage;
  final dynamic data;

  const ChangeContext(this.contextStage, this.data);
}

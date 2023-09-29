// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

Widget settingsLabel(String string, TextStyle style) => Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 18, right: 12, left: 16),
      child: Text(
        string,
        style: style,
      ),
    );

Widget timeLabel((int, int, int) time, TextStyle titleStyle) {
  final timeNow = DateTime.now();

  if (time == (timeNow.day, timeNow.month, timeNow.year)) {
    return settingsLabel("Today", titleStyle);
  } else {
    return settingsLabel(
        "${time.$1}/${time.$2}/${time.$3.toString().substring(2)}", titleStyle);
  }
}

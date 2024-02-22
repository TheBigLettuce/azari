// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../pages/more/settings/settings_label.dart';

class TimeLabel extends StatelessWidget {
  final (int, int, int) time;
  final TextStyle titleStyle;
  final DateTime now;
  final bool removePadding;

  const TimeLabel(this.time, this.titleStyle, this.now,
      {super.key, this.removePadding = false});

  @override
  Widget build(BuildContext context) {
    if (time == (now.day, now.month, now.year)) {
      return SettingsLabel(
        "Today",
        titleStyle,
        removePadding: removePadding,
      );
    } else {
      return SettingsLabel(
        "${time.$1}/${time.$2}/${time.$3.toString().substring(2)}",
        titleStyle,
        removePadding: removePadding,
      );
    }
  }
}

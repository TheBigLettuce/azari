// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/pages/more/tab_with_count.dart';

class WatchingTabCount extends StatefulWidget {
  final StreamSubscription<int> Function(void Function(int) f) createWatcher;
  final String label;

  const WatchingTabCount(this.label, {super.key, required this.createWatcher});

  @override
  State<WatchingTabCount> createState() => _WatchingTabCountState();
}

class _WatchingTabCountState extends State<WatchingTabCount> {
  late final StreamSubscription<int> watcher;
  int count = 0;

  @override
  void initState() {
    super.initState();

    watcher = widget.createWatcher((i) {
      count = i;

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabWithCount(widget.label, count);
  }
}

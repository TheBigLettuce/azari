// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";

typedef WatchFire<T> = StreamSubscription<T> Function(
  void Function(T c) f, [
  bool fire,
]);

class StatefulBadge extends StatefulWidget {
  const StatefulBadge({super.key, required this.watchCount});

  final WatchFire<int> watchCount;

  @override
  State<StatefulBadge> createState() => _StatefulBadgeState();
}

class _StatefulBadgeState extends State<StatefulBadge> {
  late final StreamSubscription<int> _watcher;

  int? count;

  @override
  void initState() {
    super.initState();

    _watcher = widget.watchCount(
      (i) {
        setState(() {
          count = i;
        });
      },
      true,
    );
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Badge.count(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      textColor: theme.colorScheme.onSurfaceVariant,
      count: count ?? -1,
    );
  }
}

class TabWithCount extends StatelessWidget {
  const TabWithCount(this.title, this.watchCount, {super.key});

  final String title;
  final WatchFire<int> watchCount;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: StatefulBadge(watchCount: watchCount),
          ),
        ],
      ),
    );
  }
}

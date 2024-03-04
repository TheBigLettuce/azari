// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../configuration/grid_fab_type.dart';

class _Fab extends StatefulWidget {
  final ScrollController controller;

  const _Fab({
    super.key,
    required this.controller,
  });

  @override
  State<_Fab> createState() => __FabState();
}

class __FabState extends State<_Fab> {
  bool showFab = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final pos = widget.controller.positions.toList();
      if (pos.isEmpty) {
        return;
      }

      pos.first.isScrollingNotifier.addListener(_listener);
    });
  }

  @override
  void dispose() {
    super.dispose();

    final pos = widget.controller.positions.toList();
    if (pos.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      pos.first.isScrollingNotifier.removeListener(_listener);
    });
  }

  void _updateFab({required bool fab}) {
    if (fab != showFab) {
      showFab = fab;
      try {
        setState(() {});
      } catch (_) {}
    }
  }

  void _listener() {
    final controller = widget.controller;

    if (controller.offset == 0) {
      _updateFab(
        fab: false,
      );
    } else {
      _updateFab(
        fab: !controller.position.isScrollingNotifier.value,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return !showFab
        ? const SizedBox.shrink()
        : GestureDetector(
            onLongPress: () {
              final scroll = widget.controller.position.maxScrollExtent;
              if (scroll.isInfinite || scroll == 0) {
                return;
              }

              widget.controller.animateTo(scroll,
                  duration: 200.ms, curve: Easing.emphasizedAccelerate);
            },
            child: FloatingActionButton(
              // elevation: 2,
              onPressed: () {
                widget.controller.animateTo(
                  0,
                  duration: const Duration(milliseconds: 200),
                  curve: Easing.emphasizedAccelerate,
                );

                StatisticsGeneral.addScrolledUp();
              },
              child: const Icon(Icons.arrow_upward),
            ),
          ).animate().fadeIn(curve: Easing.standard);
  }
}

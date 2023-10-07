// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../interfaces/booru.dart';
import '../../interfaces/cell.dart';
import 'add_rail.dart';
import 'drawer/make_drawer.dart';
import 'drawer/make_end_drawer_settings.dart';
import '../gesture_dead_zones.dart';
import '../grid/callback_grid.dart';
import '../pop_until_senitel.dart';
import 'grid_skeleton_state.dart';

Widget makeGridSkeleton<T extends Cell>(
    BuildContext context, GridSkeletonState<T> state, CallbackGrid<T> grid,
    {bool popSenitel = true,
    bool noDrawer = false,
    Booru? overrideBooru,
    Future<bool> Function()? overrideOnPop}) {
  return WillPopScope(
    onWillPop: () {
      Future<bool> pop() => overrideOnPop != null
          ? overrideOnPop()
          : popSenitel
              ? popUntilSenitel(context)
              : Future.value(true);

      final s = state.gridKey.currentState;
      if (s == null) {
        return pop();
      }

      if (s.showSearchBar && !s.flexibleAppBar) {
        s.showSearchBar = false;
        // ignore: invalid_use_of_protected_member
        s.setState(() {});
        return Future.value(false);
      }
      return pop();
    },
    child: Scaffold(
        // floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        drawerEnableOpenDragGesture:
            MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
        floatingActionButton: state.showFab
            ? GestureDetector(
                onLongPress: () {
                  if (grid.key != null &&
                      grid.key is GlobalKey<CallbackGridState>) {
                    final maxOffset = state.gridKey.currentState?.controller
                        .position.maxScrollExtent;
                    if (maxOffset == null || maxOffset.isInfinite) {
                      return;
                    }

                    HapticFeedback.vibrate();
                    (grid.key as GlobalKey<CallbackGridState>)
                        .currentState
                        ?.controller
                        .animateTo(maxOffset,
                            duration: 500.ms, curve: Curves.easeInOutSine);
                  }
                },
                child: FloatingActionButton(
                  heroTag: null,
                  onPressed: () {
                    if (grid.key != null &&
                        grid.key is GlobalKey<CallbackGridState>) {
                      (grid.key as GlobalKey<CallbackGridState>)
                          .currentState
                          ?.controller
                          .animateTo(0,
                              duration: 500.ms, curve: Curves.easeInOutSine);
                    }
                  },
                  child: const Icon(Icons.arrow_upward),
                ),
              )
            : null,
        endDrawerEnableOpenDragGesture: false,
        key: state.scaffoldKey,
        drawer: noDrawer
            ? null
            : makeDrawer(context, state.index, overrideBooru: overrideBooru),
        endDrawer:
            noDrawer ? null : makeEndDrawerSettings(context, state.scaffoldKey),
        body: gestureDeadZones(
          context,
          child: addRail(context, state.index, state.scaffoldKey, grid),
        )),
  );
}

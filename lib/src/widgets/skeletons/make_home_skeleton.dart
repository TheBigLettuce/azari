// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/gesture_dead_zones.dart';

import 'drawer/make_end_drawer_settings.dart';
import '../keybinds/describe_keys.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';

import 'skeleton_state.dart';

Widget makeHomeSkeleton(
  BuildContext context,
  String pageDescription,
  SkeletonState state,
  Widget Function(BuildContext) f, {
  required int selectedRoute,
  required Widget? navBar,
}) {
  Map<SingleActivatorDescription, Null Function()> bindings = {};

  return CallbackShortcuts(
    bindings: {
      ...bindings,
      ...keybindDescription(context, describeKeys(bindings), pageDescription,
          () {
        state.mainFocus.requestFocus();
      })
    },
    child: Focus(
      autofocus: true,
      focusNode: state.mainFocus,
      child: Scaffold(
        extendBody: selectedRoute == 3 || selectedRoute == 4 ? false : true,
        appBar: null,
        drawerEnableOpenDragGesture:
            MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
        key: state.scaffoldKey,
        endDrawer: makeEndDrawerSettings(context, state.scaffoldKey),
        bottomNavigationBar: navBar,
        body: gestureDeadZones(context, child: Builder(builder: f)),
      ),
    ),
  );
}

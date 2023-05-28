// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/system_gestures.dart';

import '../keybinds/keybinds.dart';
import '../pages/senitel.dart';
import 'drawer/add_rail.dart';
import 'drawer/drawer.dart';

Widget makeGridSkeleton(
    BuildContext context,
    int index,
    Future<bool> Function() onWillPop,
    GlobalKey<ScaffoldState> scaffoldKey,
    CallbackGrid grid) {
  return WillPopScope(
    onWillPop: onWillPop,
    child: Scaffold(
        key: scaffoldKey,
        drawer: makeDrawer(context, index),
        body: gestureDeadZones(
          context,
          child: addRail(context, index, grid),
        )),
  );
}

Widget makeSkeleton(
    BuildContext context,
    int drawerIndex,
    String pageDescription,
    FocusNode focus,
    Map<SingleActivatorDescription, Null Function()> bindings,
    PreferredSizeWidget? appBar,
    Widget child) {
  return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(context, describeKeys(bindings), pageDescription)
      },
      child: Focus(
          autofocus: true,
          focusNode: focus,
          child: WillPopScope(
            onWillPop: () => popUntilSenitel(context),
            child: Scaffold(
              appBar: appBar,
              drawer: makeDrawer(context, drawerIndex),
              body: gestureDeadZones(context,
                  child: addRail(context, drawerIndex, child)),
            ),
          )));
}

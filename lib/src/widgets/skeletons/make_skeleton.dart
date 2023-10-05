// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/gesture_dead_zones.dart';

import 'drawer/make_end_drawer_settings.dart';
import '../keybinds/describe_keys.dart';
import '../keybinds/digit_and_settings.dart';
import '../keybinds/keybind_description.dart';
import '../keybinds/single_activator_description.dart';
import '../pop_until_senitel.dart';
import 'add_rail.dart';
import 'drawer/make_drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'skeleton_state.dart';
import 'wrap_app_bar_action.dart';

Widget makeSkeleton(
  BuildContext context,
  String pageDescription,
  SkeletonState state, {
  List<Widget>? children,
  Widget Function(BuildContext context, int indx)? builder,
  Map<SingleActivatorDescription, Null Function()>? additionalBindings,
  bool popSenitel = true,
  int? itemCount,
  void Function(int route, void Function() original)? overrideChooseRoute,
  List<Widget>? appBarActions,
  Widget? customTitle,
  TabBar? tabBar,
}) {
  if (children == null && builder == null ||
      children != null && builder != null) {
    throw "only one should be specified";
  }

  if (builder != null && itemCount == null) {
    throw "itemCount should be supplied";
  }

  final insets = MediaQuery.viewPaddingOf(context);

  PreferredSizeWidget? makeAppBar() {
    if (tabBar == null) {
      return null;
    }

    return AppBar(
      automaticallyImplyLeading: true,
      actions: appBarActions != null
          ? appBarActions.map((e) => wrapAppBarAction(e)).toList()
          : [Container()],
      bottom: tabBar,
      title: customTitle ??
          Text(
            pageDescription,
          ),
    );
  }

  Widget makeBox() {
    if (children?.length == 1) {
      return children!.first;
    }

    if (children != null) {
      return ListView(
        children: children,
      );
    }

    if (builder != null) {
      return ListView.builder(
        itemBuilder: builder,
        itemCount: itemCount,
      );
    }

    return Container();
  }

  Widget makeSliver() => CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 152,
            collapsedHeight: 64,
            automaticallyImplyLeading: true,
            actions: [Container()],
            flexibleSpace: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: FlexibleSpaceBar(
                        title: customTitle ??
                            Text(
                              pageDescription,
                            ))),
                if (appBarActions != null)
                  ...appBarActions.map((e) => wrapAppBarAction(e)).toList()
              ],
            ),
          ),
          if (children != null)
            children.isEmpty
                ? const SliverFillRemaining(child: Center(child: EmptyWidget()))
                : SliverPadding(
                    padding: EdgeInsets.only(bottom: insets.bottom),
                    sliver: SliverList.list(
                      children: children,
                    ),
                  ),
          if (builder != null)
            itemCount == 0
                ? const SliverFillRemaining(child: Center(child: EmptyWidget()))
                : SliverPadding(
                    padding: EdgeInsets.only(bottom: insets.bottom),
                    sliver: SliverList.builder(
                      itemBuilder: builder,
                      itemCount: itemCount,
                    ),
                  )
        ],
      );

  Map<SingleActivatorDescription, Null Function()> bindings = {
    SingleActivatorDescription(AppLocalizations.of(context)!.back,
        const SingleActivator(LogicalKeyboardKey.escape)): () {
      if (state.scaffoldKey.currentState != null) {
        if (state.scaffoldKey.currentState!.hasEndDrawer &&
            state.scaffoldKey.currentState!.isEndDrawerOpen) {
          state.scaffoldKey.currentState?.closeEndDrawer();
        } else {
          if (popSenitel) {
            popUntilSenitel(context);
          } else {
            Navigator.pop(context);
          }
        }
      } else {
        if (popSenitel) {
          popUntilSenitel(context);
        } else {
          Navigator.pop(context);
        }
      }
    },
    if (additionalBindings != null) ...additionalBindings,
    ...digitAndSettings(context, state.index, state.scaffoldKey)
  };

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
          child: WillPopScope(
            onWillPop: () =>
                !popSenitel ? Future.value(true) : popUntilSenitel(context),
            child: Scaffold(
              appBar: makeAppBar(),
              drawerEnableOpenDragGesture:
                  MediaQuery.systemGestureInsetsOf(context) == EdgeInsets.zero,
              key: state.scaffoldKey,
              drawer: makeDrawer(context, state.index,
                  overrideChooseRoute: overrideChooseRoute),
              endDrawer: makeEndDrawerSettings(context, state.scaffoldKey),
              body: gestureDeadZones(context,
                  child: addRail(
                    context,
                    state.index,
                    state.scaffoldKey,
                    tabBar == null ? makeSliver() : makeBox(),
                  )),
            ),
          )));
}

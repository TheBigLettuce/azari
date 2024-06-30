// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";

class GlueProvider extends InheritedWidget {
  const GlueProvider({
    super.key,
    required this.generate,
    required super.child,
  });
  final SelectionGlue Function([Set<GluePreferences> preferences]) generate;

  static Widget empty(BuildContext context, {required Widget child}) {
    return GlueProvider(
      generate: ([Set<GluePreferences> set = const {}]) =>
          SelectionGlue.empty(context),
      child: child,
    );
  }

  static GenerateGlueFnc generateOf(
    BuildContext context,
  ) {
    final widget = context.dependOnInheritedWidgetOfExactType<GlueProvider>();

    return widget!.generate;
  }

  @override
  bool updateShouldNotify(GlueProvider oldWidget) =>
      generate != oldWidget.generate;
}

enum GluePreferences {
  persistentBarHeight,
  zeroSize;
}

typedef GenerateGlueFnc = SelectionGlue Function([Set<GluePreferences>]);

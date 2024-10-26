// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class FadeSidewaysPageTransitionBuilder extends PageTransitionsBuilder {
  const FadeSidewaysPageTransitionBuilder();

  static final Tween<Offset> _bottomUpTween = Tween<Offset>(
    begin: const Offset(0.25, 0),
    end: Offset.zero,
  );
  static final Animatable<double> _standardTween =
      CurveTween(curve: Easing.standard);

  static final Animatable<double> _emphasizedTween =
      CurveTween(curve: Easing.emphasizedAccelerate);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(_bottomUpTween.chain(_standardTween)),
      child: FadeTransition(
        opacity: animation.drive(_emphasizedTween),
        child: child,
      ),
    );
  }
}

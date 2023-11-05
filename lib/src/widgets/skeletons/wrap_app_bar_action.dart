// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// hardcoded as there is no simpler way
import 'dart:io';

import 'package:flutter/widgets.dart';

class WrapAppBarAction extends StatelessWidget {
  final Widget child;

  const WrapAppBarAction(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Padding(
      padding: Platform.isAndroid
          ? const EdgeInsets.only(top: 4, bottom: 4)
          : const EdgeInsets.only(top: 8, bottom: 8),
      child: child,
    ));
  }
}

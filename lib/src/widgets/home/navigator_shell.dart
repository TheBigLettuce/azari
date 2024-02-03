// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../../pages/home.dart';

class _NavigatorShell extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final void Function(bool) pop;
  final Widget child;

  const _NavigatorShell({
    super.key,
    required this.navigatorKey,
    required this.pop,
    required this.child,
  });

  @override
  State<_NavigatorShell> createState() => __NavigatorShellState();
}

class __NavigatorShellState extends State<_NavigatorShell> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: widget.pop,
      child: Navigator(
        onGenerateInitialRoutes: (navigator, initialRoute) {
          return [
            MaterialPageRoute(
              builder: (context) {
                return widget.child;
              },
            )
          ];
        },
        key: widget.navigatorKey,
      ),
    );
  }
}

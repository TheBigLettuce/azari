// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "home.dart";

class _NavigatorShell extends StatefulWidget {
  const _NavigatorShell({
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  final Widget child;

  @override
  State<_NavigatorShell> createState() => __NavigatorShellState();
}

class __NavigatorShellState extends State<_NavigatorShell> {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          MaterialPageRoute(
            builder: (_) {
              return widget.child;
            },
          ),
        ];
      },
    );
  }
}

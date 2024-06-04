// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class _BodyWrapping extends StatelessWidget {
  const _BodyWrapping({
    required this.bindings,
    required this.pageName,
    required this.children,
  });

  final String pageName;
  final Map<SingleActivatorDescription, void Function()> bindings;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        ...bindings,
        ...keybindDescription(
          context,
          describeKeys(bindings),
          pageName,
          () {},
        ),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

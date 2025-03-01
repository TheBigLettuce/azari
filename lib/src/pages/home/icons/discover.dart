// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../home.dart";

class DiscoverDestinationIcon extends StatelessWidget {
  const DiscoverDestinationIcon({
    super.key,
    required this.controller,
  });

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isSelected = CurrentRoute.of(context) == CurrentRoute.discover;

    return Animate(
      controller: controller,
      autoPlay: false,
      target: 1,
      effects: [
        ShimmerEffect(
          angle: math.pi / -5,
          duration: 440.ms,
          colors: [
            colorScheme.primary.withValues(alpha: isSelected ? 1 : 0),
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.indigo,
            Colors.purple,
            Colors.red,
          ],
        ),
      ],
      child: Icon(
        isSelected ? Icons.public_rounded : Icons.public_outlined,
        color: isSelected ? colorScheme.primary : null,
      ),
    );
  }
}

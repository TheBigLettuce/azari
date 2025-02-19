// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../configuration/grid_fab_type.dart";

class _Fab extends StatelessWidget {
  const _Fab(
      // {super.key}
      );

  @override
  Widget build(BuildContext context) {
    final showFab = IsScrollingNotifier.of(context);

    return Animate(
      target: showFab ? 1 : 0,
      autoPlay: false,
      effects: const [
        FadeEffect(
          delay: Duration(milliseconds: 80),
          duration: Duration(milliseconds: 220),
          begin: 0,
          end: 1,
          curve: Easing.standard,
        ),
        ScaleEffect(
          delay: Duration(milliseconds: 80),
          duration: Duration(milliseconds: 180),
          curve: Easing.emphasizedDecelerate,
          end: Offset(1, 1),
          begin: Offset.zero,
        ),
      ],
      child: GestureDetector(
        onLongPress: () {
          final controller = GridScrollNotifier.of(context);
          final scroll = controller.position.maxScrollExtent;
          if (scroll.isInfinite || scroll == 0) {
            return;
          }

          controller.animateTo(
            scroll,
            duration: 200.ms,
            curve: Easing.emphasizedAccelerate,
          );
        },
        child: FloatingActionButton(
          onPressed: () {
            GridScrollNotifier.of(context).animateTo(
              0,
              duration: const Duration(milliseconds: 200),
              curve: Easing.emphasizedAccelerate,
            );

            StatisticsGeneralService.addScrolledUp(1);
          },
          child: const Icon(Icons.arrow_upward_rounded),
        ),
      ),
    );
  }
}

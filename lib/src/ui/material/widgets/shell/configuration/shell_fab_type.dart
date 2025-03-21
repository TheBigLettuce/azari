// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

sealed class ShellFabType {
  const ShellFabType();

  Widget widget(BuildContext context);
}

class NoShellFab implements ShellFabType {
  const NoShellFab();

  @override
  Widget widget(BuildContext context) => const SizedBox.shrink();
}

class DefaultShellFab implements ShellFabType {
  const DefaultShellFab();

  @override
  Widget widget(BuildContext context) {
    return IsScrollingNotifier(
      notifier: ShellScrollNotifier.fabNotifierOf(context),
      child: const _Fab(),
    );
  }
}

class OverrideShellFab implements ShellFabType {
  const OverrideShellFab(this.child);

  final Widget Function() child;

  @override
  Widget widget(BuildContext context) {
    return IsScrollingNotifier(
      notifier: ShellScrollNotifier.fabNotifierOf(context),
      child: child(),
    );
  }
}

class IsScrollingNotifier extends InheritedNotifier<ValueNotifier<bool>> {
  const IsScrollingNotifier({
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static bool of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<IsScrollingNotifier>();

    return widget!.notifier!.value;
  }
}

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
          final controller = ShellScrollNotifier.of(context);
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
            ShellScrollNotifier.of(context).animateTo(
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

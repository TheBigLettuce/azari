// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/notifiers/selection_count.dart";

class WrapGridActionButton extends StatefulWidget {
  const WrapGridActionButton(
    this.icon,
    this.onPressed,
    this.addBadge, {
    super.key,
    this.color,
    required this.onLongPress,
    required this.whenSingleContext,
    required this.play,
    required this.animate,
    this.watch,
  });

  final IconData icon;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final bool addBadge;
  final Color? color;
  final bool animate;
  final bool play;
  final BuildContext? whenSingleContext;

  final WatchFire<(IconData?, Color?, bool?)>? watch;

  @override
  State<WrapGridActionButton> createState() => _WrapGridActionButtonState();
}

class _WrapGridActionButtonState extends State<WrapGridActionButton> {
  AnimationController? _controller;

  StreamSubscription<(IconData?, Color?, bool?)>? _subscr;

  late (IconData, Color?, bool) data = (widget.icon, widget.color, widget.play);

  @override
  void initState() {
    _subscr = widget.watch?.call(
      (d) {
        // if (d.$3 != null && !data.$3 && d.$3!) {
        //   _controller?.reset();
        //   _controller?.animateTo(1).then((value) => _controller?.animateBack(0));
        // }

        data = (d.$1 ?? data.$1, d.$2, d.$3 ?? data.$3);

        // print

        setState(() {});
      },
      true,
    );

    super.initState();
  }

  @override
  void dispose() {
    _subscr?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icn = Icon(data.$1, color: data.$2);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: GestureDetector(
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                widget.onLongPress!();
                HapticFeedback.lightImpact();
              },
        child: IconButton(
          style: const ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.elliptical(10, 10)),
              ),
            ),
            // backgroundColor:
            //     data.$2 != null ? WidgetStatePropertyAll(data.$2) : null,
          ),
          onPressed: widget.whenSingleContext != null &&
                  SelectionCountNotifier.countOf(widget.whenSingleContext!) != 1
              ? null
              : widget.onPressed == null
                  ? null
                  : () {
                      if (widget.animate && widget.play) {
                        _controller?.reset();
                        _controller
                            ?.animateTo(1)
                            .then((value) => _controller?.animateBack(0));
                      }
                      HapticFeedback.selectionClick();
                      widget.onPressed!();
                    },
          icon: widget.animate
              ? Animate(
                  effects: [
                    ScaleEffect(
                      duration: 150.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(2, 2),
                      curve: Easing.emphasizedAccelerate,
                    ),
                  ],
                  onInit: (controller) {
                    _controller = controller;
                  },
                  autoPlay: false,
                  child: widget.addBadge
                      ? Badge.count(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          textColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          count: SelectionCountNotifier.countOf(context),
                          child: icn,
                          // child: iconBtn(context),
                        )
                      : icn,
                )
              : widget.addBadge
                  ? Badge.count(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      textColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      count: SelectionCountNotifier.countOf(context),
                      child: icn,
                      // child: iconBtn(context),
                    )
                  : icn,
        ),
      ),
    );
  }
}

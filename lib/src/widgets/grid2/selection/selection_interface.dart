// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/notifiers/cell_provider.dart';
import 'package:gallery/src/widgets/notifiers/selection_glue.dart';

class SelectionInterface<T extends Cell> {
  final _selected = <int, T>{};
  int? _lastSelected;

  final void Function(int) tickSelectionCount;

  void use(void Function(List<T> l) f) {
    f(_selected.values.toList());
    reset();
  }

  void reset() {
    tickSelectionCount(0);
    _selected.clear();
    _lastSelected = null;
  }

  int count() => _selected.length;

  bool isSelected(BuildContext context, int indx) =>
      indx.isNegative ? false : _selected.containsKey(indx);

  void add(BuildContext context, int id, T selection, [bool tick = true]) {
    if (id.isNegative) {
      return;
    }

    if (_selected.isEmpty) {
      SelectionGlueNotifier.of<T>(context).open(context, this);
    }

    _selected[id] = selection;
    _lastSelected = id;

    if (tick) {
      tickSelectionCount(_selected.length);
    }
  }

  void remove(BuildContext context, int id, [bool tick = true]) {
    _selected.remove(id);
    if (_selected.isEmpty) {
      SelectionGlueNotifier.of<T>(context).close();
      _lastSelected = null;
    }

    if (tick) {
      tickSelectionCount(_selected.length);
    }
  }

  void selectUnselectUntil(BuildContext context, int indx,
      {List<int>? selectFrom}) {
    if (_lastSelected == null) {
      selectOrUnselect(context, indx);
    } else {
      final last = selectFrom?.indexOf(_lastSelected!) ?? _lastSelected!;
      indx = selectFrom?.indexOf(indx) ?? indx;
      if (_lastSelected == indx) {
        return;
      }

      final selection = !isSelected(context, indx);
      final getCell = CellProvider.of<T>(context);

      if (indx < last) {
        for (var i = last; i >= indx; i--) {
          if (selection) {
            _selected[selectFrom?[i] ?? i] = getCell(selectFrom?[i] ?? i)!;
          } else {
            remove(context, selectFrom?[i] ?? i, false);
          }
          _lastSelected = selectFrom?[i] ?? i;
        }
        tickSelectionCount(_selected.length);
      } else if (indx > last) {
        for (var i = last; i <= indx; i++) {
          if (selection) {
            _selected[selectFrom?[i] ?? i] = getCell(selectFrom?[i] ?? i)!;
          } else {
            remove(context, selectFrom?[i] ?? i, false);
          }
          _lastSelected = selectFrom?[i] ?? i;
        }
        tickSelectionCount(_selected.length);
      }
    }
  }

  void selectOrUnselect(BuildContext context, int index) {
    if (!isSelected(context, index)) {
      add(context, index, CellProvider.getOf<T>(context, index));
    } else {
      remove(context, index);
    }

    HapticFeedback.selectionClick();
  }

  SelectionInterface(this.tickSelectionCount);
}

class WrapGridActionButton extends StatefulWidget {
  final IconData icon;
  final void Function()? onPressed;
  final bool addBadge;
  final String label;
  final bool? followColorTheme;
  final Color? backgroundColor;
  final Color? color;
  final bool animate;
  final bool play;

  const WrapGridActionButton(
      this.icon, this.onPressed, this.addBadge, this.label,
      {super.key,
      this.followColorTheme,
      this.backgroundColor,
      this.color,
      this.play = false,
      this.animate = false});

  @override
  State<WrapGridActionButton> createState() => _WrapGridActionButtonState();
}

class _WrapGridActionButtonState extends State<WrapGridActionButton> {
  AnimationController? _controller;

  @override
  Widget build(BuildContext context) {
    final icn = Icon(widget.icon,
        color: widget.color ??
            (widget.followColorTheme == true
                ? null
                : Theme.of(context).colorScheme.inversePrimary));

    Widget iconBtn(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: IconButton(
          style: ButtonStyle(
              shape: const MaterialStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.elliptical(10, 10)))),
              backgroundColor: widget.backgroundColor != null
                  ? MaterialStatePropertyAll(widget.backgroundColor)
                  : widget.followColorTheme == true
                      ? null
                      : MaterialStatePropertyAll(widget.onPressed == null
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5)
                          : Theme.of(context).colorScheme.primary)),
          onPressed: widget.onPressed == null
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
                        curve: Curves.easeInOutBack),
                  ],
                  onInit: (controller) {
                    _controller = controller;
                  },
                  autoPlay: false,
                  child: icn,
                )
              : icn,
        ),
      );
    }

    return widget.addBadge
        ? Badge(
            label: Text(widget.label),
            child: iconBtn(context),
          )
        : iconBtn(context);
  }
}

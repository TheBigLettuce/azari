// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../shell_scope.dart";

class WrapSelection<T extends CellBase> extends StatelessWidget {
  const WrapSelection({
    super.key,
    required this.thisIndx,
    required this.description,
    required this.selectFrom,
    required this.onPressed,
    this.onDoubleTap,
    this.limitedSize = false,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
    required this.child,
  });

  final bool limitedSize;

  final int thisIndx;

  final List<int>? selectFrom;

  final CellStaticData description;

  final ShapeBorder shape;

  final VoidCallback? onPressed;
  final ContextCallback? onDoubleTap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    SelectionCountNotifier.maybeCountOf(context);
    final selection = ShellSelectionHolder.maybeOf(context);

    if (selection == null) {
      return _WrappedSelectionCore(
        thisIndx: thisIndx,
        selectFrom: selectFrom,
        onDoubleTap: onDoubleTap,
        shape: shape,
        selection: null,
        onPressed: onPressed,
        limitedSize: limitedSize,
        child: child,
      );
    } else if (selection.actions.isEmpty) {
      return _WrappedSelectionCore(
        thisIndx: thisIndx,
        selectFrom: selectFrom,
        onDoubleTap: onDoubleTap,
        shape: shape,
        selection: null,
        onPressed: onPressed,
        limitedSize: limitedSize,
        child: child,
      );
    }

    if (thisIndx.isNegative || description.ignoreSwipeSelectGesture) {
      return _WrappedSelectionCore(
        selection: selection,
        onDoubleTap: onDoubleTap,
        selectFrom: selectFrom,
        shape: shape,
        onPressed: onPressed,
        thisIndx: thisIndx,
        limitedSize: limitedSize,
        child: child,
      );
    }

    return DragTarget(
      onAcceptWithDetails: (data) {
        selection.selectOrUnselect(
          thisIndx,
        );
      },
      onLeave: (data) {
        final c = ShellScrollNotifier.of(context);
        if (!c.hasClients) {
          return;
        }

        if (c.position.isScrollingNotifier.value &&
            selection.isSelected(thisIndx)) {
          return;
        }

        selection.selectOrUnselect(thisIndx);
      },
      onWillAcceptWithDetails: (data) => true,
      builder: (context, _, __) {
        if (selection.isNotEmpty) {
          return Draggable(
            data: 1,
            affinity: Axis.horizontal,
            feedback: const SizedBox(),
            child: _WrappedSelectionCore(
              thisIndx: thisIndx,
              shape: shape,
              onPressed: onPressed,
              onDoubleTap: onDoubleTap,
              selectFrom: selectFrom,
              selection: selection,
              limitedSize: limitedSize,
              child: child,
            ),
          );
        }

        return LongPressDraggable(
          data: 1,
          feedback: const SizedBox(),
          child: _WrappedSelectionCore(
            thisIndx: thisIndx,
            shape: shape,
            onPressed: onPressed,
            onDoubleTap: onDoubleTap,
            selectFrom: selectFrom,
            selection: selection,
            limitedSize: limitedSize,
            child: child,
          ),
        );
      },
    );
  }
}

class _WrappedSelectionCore extends StatefulWidget {
  const _WrappedSelectionCore({
    required this.thisIndx,
    required this.selectFrom,
    required this.selection,
    required this.onPressed,
    required this.onDoubleTap,
    required this.limitedSize,
    required this.shape,
    required this.child,
  });

  final bool limitedSize;

  final int thisIndx;

  final List<int>? selectFrom;

  final ShellSelectionHolder? selection;

  final VoidCallback? onPressed;
  final ContextCallback? onDoubleTap;

  final ShapeBorder shape;

  final Widget child;

  @override
  State<_WrappedSelectionCore> createState() => __WrappedSelectionCoreState();
}

class __WrappedSelectionCoreState extends State<_WrappedSelectionCore>
    with SingleTickerProviderStateMixin {
  ShellSelectionHolder get selection => widget.selection!;
  int get thisIndx => widget.thisIndx;

  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void _playAnimation() {
    controller.reset();
    controller.forward().then((value) => controller.reverse());
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selection == null) {
      return InkWell(
        onDoubleTap: widget.onDoubleTap == null
            ? null
            : () => widget.onDoubleTap!(context),
        customBorder: widget.shape,
        onTap: thisIndx.isNegative && widget.onPressed == null
            ? null
            : widget.onPressed,
        child: widget.child,
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final child = Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(0.5),
            child: AnimatedContainer(
              decoration: ShapeDecoration(
                shape: widget.shape,
                color: selection.isSelected(thisIndx)
                    ? colorScheme.primary
                    : colorScheme.primary.withValues(alpha: 0),
              ),
              duration: const Duration(milliseconds: 160),
              curve: Easing.emphasizedAccelerate,
              child: _LongPressMoveGesture(
                selection: widget.selection!,
                thisIndx: widget.thisIndx,
                selectFrom: widget.selectFrom,
                child: GestureDetector(
                  child: Builder(
                    builder: (context) => InkWell(
                      onDoubleTap: widget.onDoubleTap == null ||
                              widget.selection!.isNotEmpty
                          ? null
                          : () => widget.onDoubleTap!(context),
                      customBorder: widget.shape,
                      onTap: selection.isEmpty
                          ? thisIndx.isNegative && widget.onPressed == null
                              ? null
                              : widget.onPressed
                          : () {
                              selection.selectOrUnselect(thisIndx);
                            },
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (selection.isSelected(thisIndx) && !widget.limitedSize) ...[
          IgnorePointer(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: widget.shape,
                color: colorScheme.primaryContainer.withValues(alpha: 0.15),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: theme.iconTheme.size,
                  height: theme.iconTheme.size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.check_rounded,
                        color: colorScheme.primaryFixedDim,
                        shadows: const [
                          Shadow(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 160),
                curve: Easing.emphasizedAccelerate,
              ),
        ],
      ],
    );

    return WrapperSelectionAnimation(
      play: _playAnimation,
      child: Animate(
        autoPlay: false,
        controller: controller,
        effects: [
          MoveEffect(
            duration: 220.ms,
            curve: Easing.emphasizedAccelerate,
            begin: Offset.zero,
            end: const Offset(0, -10),
          ),
          TintEffect(
            duration: 220.ms,
            begin: 0,
            end: 0.1,
            curve: Easing.standardAccelerate,
            color: colorScheme.primary,
          ),
        ],
        child: child,
      ),
    );
  }
}

class _LongPressMoveGesture extends StatefulWidget {
  const _LongPressMoveGesture({
    super.key,
    required this.selection,
    required this.thisIndx,
    required this.selectFrom,
    required this.child,
  });

  final int thisIndx;

  final ShellSelectionHolder selection;
  final List<int>? selectFrom;

  final Widget child;

  @override
  State<_LongPressMoveGesture> createState() => __LongPressMoveGestureState();
}

class __LongPressMoveGestureState extends State<_LongPressMoveGesture> {
  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;

    if (widget.selection.isEmpty) {
      return widget.child;
    }

    final gestures = <Type, GestureRecognizerFactory>{
      LongPressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                    debugOwner: this,
                    postAcceptSlopTolerance: 30,
                  ), (LongPressGestureRecognizer instance) {
        instance
          ..onLongPress = selection.isEmpty
              ? null
              : () {
                  selection.selectUnselectUntil(
                    widget.thisIndx,
                    selectFrom: widget.selectFrom,
                  );
                  HapticFeedback.vibrate();
                }
          ..onLongPressMoveUpdate = (details) {
            if (details.offsetFromOrigin.dy >= 18) {
              widget.selection.selectAll();
            }
          };
      }),
    };

    return RawGestureDetector(
      gestures: gestures,
      child: widget.child,
    );
  }
}

class WrapperSelectionAnimation extends InheritedWidget {
  const WrapperSelectionAnimation({
    super.key,
    required this.play,
    required super.child,
  });

  final VoidCallback play;

  static void tryPlayOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<WrapperSelectionAnimation>();

    widget?.play();
  }

  @override
  bool updateShouldNotify(WrapperSelectionAnimation oldWidget) {
    return play != oldWidget.play;
  }
}

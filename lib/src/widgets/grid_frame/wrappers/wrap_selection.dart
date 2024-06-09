// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class WrapSelection<T extends CellBase> extends StatelessWidget {
  const WrapSelection({
    super.key,
    required this.thisIndx,
    required this.description,
    required this.selectFrom,
    required this.selection,
    required this.functionality,
    required this.onPressed,
    this.limitedSize = false,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
    required this.child,
  });

  final GridSelection<T> selection;
  final List<int>? selectFrom;
  final int thisIndx;
  final CellStaticData description;

  final void Function()? onPressed;

  final GridFunctionality<T> functionality;
  final bool limitedSize;
  final ShapeBorder shape;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    SelectionCountNotifier.countOf(context);

    if (selection.addActions.isEmpty) {
      return _WrappedSelectionCore(
        thisIndx: thisIndx,
        selectFrom: selectFrom,
        shape: shape,
        selection: null,
        onPressed: onPressed,
        functionality: functionality,
        limitedSize: limitedSize,
        child: child,
      );
    }

    return thisIndx.isNegative || description.ignoreSwipeSelectGesture
        ? _WrappedSelectionCore<T>(
            selection: selection,
            functionality: functionality,
            selectFrom: selectFrom,
            shape: shape,
            onPressed: onPressed,
            thisIndx: thisIndx,
            limitedSize: limitedSize,
            child: child,
          )
        : DragTarget(
            onAcceptWithDetails: (data) {
              selection.selectOrUnselect(context, thisIndx);
            },
            onLeave: (data) {
              final c = GridScrollNotifier.of(context);
              if (!c.hasClients) {
                return;
              }

              if (c.position.isScrollingNotifier.value &&
                  selection.isSelected(thisIndx)) {
                return;
              }

              selection.selectOrUnselect(context, thisIndx);
            },
            onWillAcceptWithDetails: (data) => true,
            builder: (context, _, __) {
              return Draggable(
                data: 1,
                affinity: Axis.horizontal,
                feedback: const SizedBox(),
                child: _WrappedSelectionCore(
                  functionality: functionality,
                  thisIndx: thisIndx,
                  shape: shape,
                  onPressed: onPressed,
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

class _WrappedSelectionCore<T extends CellBase> extends StatefulWidget {
  const _WrappedSelectionCore({
    required this.thisIndx,
    required this.selectFrom,
    required this.selection,
    required this.functionality,
    required this.onPressed,
    required this.limitedSize,
    required this.shape,
    required this.child,
  });
  final int thisIndx;
  final GridSelection<T>? selection;
  final List<int>? selectFrom;
  final GridFunctionality<T> functionality;
  final bool limitedSize;

  final void Function()? onPressed;

  final ShapeBorder shape;

  final Widget child;

  @override
  State<_WrappedSelectionCore<T>> createState() =>
      __WrappedSelectionCoreState<T>();
}

class __WrappedSelectionCoreState<T extends CellBase>
    extends State<_WrappedSelectionCore<T>>
    with SingleTickerProviderStateMixin {
  GridSelection<T> get selection => widget.selection!;
  GridFunctionality<T> get functionality => widget.functionality;
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

  @override
  Widget build(BuildContext context) {
    if (widget.selection == null) {
      return InkWell(
        customBorder: widget.shape,
        onDoubleTap: widget.functionality.download != null
            ? () {
                controller.reset();
                controller.forward().then((value) => controller.reverse());
                HapticFeedback.selectionClick();
                widget.functionality.download!(thisIndx);
              }
            : null,
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
                    : colorScheme.primary.withOpacity(0),
              ),
              duration: const Duration(milliseconds: 160),
              curve: Easing.emphasizedAccelerate,
              child: _LongPressMoveGesture(
                selection: widget.selection!,
                thisIndx: widget.thisIndx,
                selectFrom: widget.selectFrom,
                child: GestureDetector(
                  child: InkWell(
                    customBorder: widget.shape,
                    onDoubleTap: widget.functionality.download != null &&
                            widget.selection!.isEmpty
                        ? () {
                            controller.reset();
                            controller
                                .forward()
                                .then((value) => controller.reverse());
                            HapticFeedback.selectionClick();
                            widget.functionality.download!(thisIndx);
                          }
                        : null,
                    onTap: selection.isEmpty
                        ? thisIndx.isNegative && widget.onPressed == null
                            ? null
                            : widget.onPressed
                        : () {
                            selection.selectOrUnselect(context, thisIndx);
                          },
                    child: widget.child,
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
                color: colorScheme.primaryContainer.withOpacity(0.15),
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
                      color: Colors.black.withOpacity(0.5),
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

    return Animate(
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
    );
  }
}

class _LongPressMoveGesture<T extends CellBase> extends StatefulWidget {
  const _LongPressMoveGesture({
    super.key,
    required this.selection,
    required this.thisIndx,
    required this.selectFrom,
    required this.child,
  });
  final GridSelection<T> selection;
  final int thisIndx;
  final List<int>? selectFrom;

  final Widget child;

  @override
  State<_LongPressMoveGesture> createState() => __LongPressMoveGestureState();
}

class __LongPressMoveGestureState extends State<_LongPressMoveGesture> {
  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;

    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(
                      debugOwner: this,
                      postAcceptSlopTolerance: 30,
                    ), (LongPressGestureRecognizer instance) {
          instance
            ..onLongPress = selection.isEmpty
                ? widget.thisIndx.isNegative || selection.addActions.isEmpty
                    ? null
                    : () {
                        selection.selectOrUnselect(context, widget.thisIndx);
                      }
                : () {
                    selection.selectUnselectUntil(
                      context,
                      widget.thisIndx,
                      selectFrom: widget.selectFrom,
                    );
                    HapticFeedback.vibrate();
                  }
            ..onLongPressMoveUpdate = (details) {
              if (details.offsetFromOrigin.dy >= 18) {
                widget.selection.selectAll(context);
              }
            };
        }),
      },
      child: widget.child,
    );
  }
}

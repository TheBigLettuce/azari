// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/ui/material/widgets/action_button.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class SelectionBar extends StatefulWidget {
  const SelectionBar({
    super.key,
    required this.selectionActions,
    required this.actions,
  });

  final SelectionActions selectionActions;
  final List<SelectionButton> actions;

  @override
  State<SelectionBar> createState() => _SelectionBarState();
}

class _SelectionBarState extends State<SelectionBar> {
  late final StreamSubscription<void> _countEvents;

  @override
  void initState() {
    super.initState();

    _countEvents = widget.selectionActions.controller.countEvents.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countEvents.cancel();

    super.dispose();
  }

  Widget _wrapped(SelectionButton e) => ActionButton(
        e.icon,
        e.consume,
        animate: e.animate,
        onLongPress: null,
        play: e.play,
        animation: const [],
        addBorder: false,
        taskTag: e.taskTag,
      );

  void _unselectAll() {
    widget.selectionActions.controller.setCount(0);
    HapticFeedback.mediumImpact();
  }

  List<PopupMenuEntry<void>> itemBuilderPopup(BuildContext context) {
    return widget.actions
        .getRange(0, widget.actions.length - 3)
        .map(
          (e) => PopupMenuItem<void>(
            onTap: e.consume,
            child: AbsorbPointer(
              child: _wrapped(e),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bottomBarColor = colorScheme.surface.withValues(alpha: 0.95);
    final textColor = colorScheme.onPrimary.withValues(alpha: 0.8);
    final boxColor = colorScheme.primary.withValues(alpha: 0.8);

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: textColor,
    );

    final actions = widget.actions.length < 4
        ? widget.actions.map(_wrapped).toList()
        : widget.actions
            .getRange(
              widget.actions.length != 4
                  ? widget.actions.length - 3
                  : widget.actions.length - 3 - 1,
              widget.actions.length,
            )
            .map(_wrapped)
            .toList();

    final count = widget.selectionActions.controller.count.toString();

    return Stack(
      fit: StackFit.passthrough,
      children: [
        const SizedBox(
          height: 80,
          child: AbsorbPointer(
            child: SizedBox.shrink(),
          ),
        ),
        BottomAppBar(
          color: bottomBarColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.actions.length > 4)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  position: PopupMenuPosition.under,
                  itemBuilder: itemBuilderPopup,
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 4,
                    children: actions,
                  ),
                ),
              ),
              Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 28,
                      minWidth: 28,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: boxColor,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Text(
                            count,
                            style: textStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(right: 4)),
                  IconButton.filledTonal(
                    onPressed: _unselectAll,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Action which can be taken upon a selected group of cells.
class SelectionBarAction {
  const SelectionBarAction(
    this.icon,
    this.onPress,
    this.closeOnPress, {
    this.showOnlyWhenSingle = false,
    this.backgroundColor,
    this.onLongPress,
    this.color,
    this.animate = false,
    this.play = true,
    this.taskTag,
  });

  /// If [showOnlyWhenSingle] is true, then this button will be only active if only a single
  /// element is currently selected.
  final bool showOnlyWhenSingle;

  /// If [closeOnPress] is true, then the bottom sheet will be closed immediately after this
  /// button has been pressed.
  final bool closeOnPress;

  final bool animate;
  final bool play;

  final Type? taskTag;

  /// Icon of the button.
  final IconData icon;

  final Color? backgroundColor;
  final Color? color;

  /// [onPress] is called when the button gets pressed,
  /// if [showOnlyWhenSingle] is true then this is guranteed to be called
  /// with [selected] elements zero or one.
  final void Function(List<CellBase> selected) onPress;

  final void Function(List<CellBase> selected)? onLongPress;
}

abstract class SelectionActions {
  factory SelectionActions() => _DefaultSelectionActions();

  SelectionAreaSize get size;

  SelectionController get controller;

  Stream<List<SelectionButton> Function()?> connect(SelectionAreaSize size);

  Widget inject(Widget child);

  void dispose();

  static SelectionActions of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_Notifier>();

    return widget!.instance;
  }

  static SelectionController controllerOf(BuildContext context) =>
      of(context).controller;
}

abstract class SelectionController {
  bool get isExpanded;
  bool get isVisible;

  int get count;

  Stream<void> get expandedEvents;
  Stream<void> get countEvents;
  Stream<void> get visibilityEvents;

  void setCount(int count, [List<SelectionButton> Function()? factory]);
  void setVisibility(bool isVisible);
  void setExpanded(bool isExpanded);
}

class SelectionAreaSize {
  const SelectionAreaSize({
    required this.base,
    required this.expanded,
  });

  final double base;
  final double expanded;
}

class SelectionButton {
  const SelectionButton(
    this.icon,
    this.consume,
    this.closeOnPress,
    this.taskTag, {
    this.animate = false,
    this.play = true,
  });

  final bool closeOnPress;

  final bool animate;
  final bool play;

  final IconData icon;

  final VoidCallback consume;
  final Type? taskTag;
}

mixin DefaultSelectionEventsMixin<S extends StatefulWidget> on State<S> {
  SelectionAreaSize get selectionSizes;

  late final StreamSubscription<List<SelectionButton> Function()?>
      _actionEvents;

  late final StreamSubscription<void> _expandedEvents;

  List<SelectionButton> _actions = const [];
  List<SelectionButton> Function()? _prevFunc;

  SelectionActions? _selectionActions;

  SelectionActions get selectionActions => _selectionActions!;
  List<SelectionButton> get actions => _actions;

  void animateNavBar(bool show) {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_selectionActions == null) {
      _selectionActions = SelectionActions.of(context);
      _actionEvents =
          _selectionActions!.connect(selectionSizes).listen((newActions) {
        if (_prevFunc == newActions) {
          return;
        } else if (newActions == null) {
          setState(() {
            _prevFunc = null;
            _actions = const [];
          });
        } else {
          setState(() {
            _actions = newActions();
            _prevFunc = newActions;
          });
        }
      });

      _expandedEvents =
          _selectionActions!.controller.expandedEvents.listen((_) {
        animateNavBar(_selectionActions!.controller.isExpanded);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _expandedEvents.cancel();
    _actionEvents.cancel();

    super.dispose();
  }
}

class _DefaultSelectionController implements SelectionController {
  _DefaultSelectionController(this.sink);

  final StreamSink<List<SelectionButton> Function()?> sink;

  final _countEvents = StreamController<void>.broadcast();
  final _expandedEvents = StreamController<void>.broadcast();
  final _visibilityEvents = StreamController<void>.broadcast();

  @override
  int count = 0;

  @override
  bool isExpanded = false;

  @override
  bool isVisible = true;

  @override
  Stream<void> get countEvents => _countEvents.stream;

  @override
  Stream<void> get expandedEvents => _expandedEvents.stream;

  @override
  Stream<void> get visibilityEvents => _visibilityEvents.stream;

  @override
  void setCount(int count_, [List<SelectionButton> Function()? factory]) {
    assert(!count_.isNegative);

    count = count_;
    _countEvents.add(null);

    if (count_ == 0) {
      isExpanded = false;
      _expandedEvents.add(null);
      sink.add(null);
    } else {
      sink.add(factory);
    }
  }

  @override
  void setExpanded(bool isExpanded_) {
    isExpanded = isExpanded_;
    _expandedEvents.add(null);
  }

  @override
  void setVisibility(bool isVisible_) {
    isVisible = isVisible_;
    _visibilityEvents.add(null);
  }

  void dispose() {
    _visibilityEvents.close();
    _countEvents.close();
    _expandedEvents.close();
  }
}

class _DefaultSelectionActions implements SelectionActions {
  _DefaultSelectionActions() {
    controller = _DefaultSelectionController(_events.sink);
  }

  final _events =
      StreamController<List<SelectionButton> Function()?>.broadcast();

  @override
  late final _DefaultSelectionController controller;

  @override
  SelectionAreaSize size = const SelectionAreaSize(base: 0, expanded: 0);

  @override
  Stream<List<SelectionButton> Function()?> connect(
    SelectionAreaSize size_,
  ) {
    size = size_;

    return _events.stream;
  }

  @override
  Widget inject(Widget child) => _Notifier(
        instance: this,
        child: child,
      );

  @override
  void dispose() {
    _events.close();
    controller.dispose();
  }
}

class _Notifier extends InheritedWidget {
  const _Notifier({
    // super.key,
    required this.instance,
    required super.child,
  });

  final SelectionActions instance;

  @override
  bool updateShouldNotify(_Notifier oldWidget) =>
      instance != oldWidget.instance;
}

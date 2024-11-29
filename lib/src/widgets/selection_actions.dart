// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";

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
    this.closeOnPress, {
    this.animate = false,
    this.play = true,
  });

  final bool closeOnPress;

  final bool animate;
  final bool play;

  final IconData icon;

  final VoidCallback consume;
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

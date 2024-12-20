// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

/// Action which can be taken upon a selected group of cells.
class GridAction<T extends CellBase> {
  const GridAction(
    this.icon,
    this.onPress,
    this.closeOnPress, {
    this.showOnlyWhenSingle = false,
    this.backgroundColor,
    this.onLongPress,
    this.color,
    this.animate = false,
    this.play = true,
  });

  /// If [showOnlyWhenSingle] is true, then this button will be only active if only a single
  /// element is currently selected.
  final bool showOnlyWhenSingle;

  /// If [closeOnPress] is true, then the bottom sheet will be closed immediately after this
  /// button has been pressed.
  final bool closeOnPress;

  final bool animate;
  final bool play;

  /// Icon of the button.
  final IconData icon;

  final Color? backgroundColor;
  final Color? color;

  /// [onPress] is called when the button gets pressed,
  /// if [showOnlyWhenSingle] is true then this is guranteed to be called
  /// with [selected] elements zero or one.
  final void Function(List<T> selected) onPress;

  final void Function(List<T> selected)? onLongPress;
}

class ImageViewAction {
  const ImageViewAction(
    this.icon,
    this.onPress, {
    this.color,
    this.animation = const [
      ScaleEffect(
        delay: Duration(milliseconds: 40),
        duration: Durations.short3,
        begin: Offset(1, 1),
        end: Offset(2, 2),
        curve: Easing.emphasizedDecelerate,
      ),
    ],
    this.animate = false,
    this.play = true,
    this.watch,
    this.longLoadingNotifier,
  });

  final bool animate;
  final bool play;

  /// Icon of the button.
  final IconData icon;

  /// [onPress] is called when the button gets pressed,
  /// if [showOnlyWhenSingle] is true then this is guranteed to be called
  /// with [selected] elements zero or one.
  final void Function(int index)? onPress;

  final Color? color;
  final List<Effect<dynamic>> animation;

  final ValueNotifier<Future<void>?>? longLoadingNotifier;

  final WatchFire<(IconData?, Color?, bool?)>? watch;

  ImageViewAction copy(
    IconData? icon,
    Color? color,
    bool? play,
    bool? animate,
  ) =>
      ImageViewAction(
        icon ?? this.icon,
        onPress,
        color: color ?? this.color,
        animate: animate ?? this.animate,
        play: play ?? this.play,
      );
}

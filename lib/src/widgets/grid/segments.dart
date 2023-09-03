// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

/// Segments of the grid.
class Segments<T> {
  /// Under [unsegmentedLabel] appear cells on which [segment] returns null,
  /// or are single standing.
  final String unsegmentedLabel;

  /// Under [injectedLabel] appear [injectedSegments].
  /// All pinned.
  final String injectedLabel;

  /// [injectedSegments] make it possible to add foreign cell on the segmented grid.
  /// [segment] is not called on [injectedSegments].
  final List<T> injectedSegments;

  /// Segmentation function.
  /// If [sticky] is true, then even if the cell is single standing it will appear
  /// as a single element segment on the grid.
  final (String? segment, bool sticky) Function(T cell) segment;

  /// If [addToSticky] is not null. then it will be possible to make
  /// segments sticky on the grid.
  /// If [unsticky] is true, then instead of stickying, unstickying should happen.
  final void Function(String seg, {bool? unsticky})? addToSticky;

  const Segments(this.segment, this.unsegmentedLabel,
      {this.addToSticky,
      this.injectedSegments = const [],
      this.injectedLabel = "Special"});

  static Widget label(BuildContext context, String text, bool sticky,
          void Function()? onLongPress) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 16, left: 8, right: 8),
          child: GestureDetector(
            onLongPress: onLongPress,
            child: SizedBox.fromSize(
              size: Size.fromHeight(
                  (Theme.of(context).textTheme.headlineLarge?.fontSize ?? 24) +
                      8),
              child: Stack(
                children: [
                  Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(letterSpacing: 2),
                  ),
                  if (sticky)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.push_pin_outlined),
                    ),
                ],
              ),
            ),
          ));
}

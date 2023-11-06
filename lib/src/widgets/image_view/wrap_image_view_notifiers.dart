// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/notifiers/app_bar_visibility.dart';
import 'package:gallery/src/widgets/notifiers/current_cell.dart';
import 'package:gallery/src/widgets/notifiers/loading_progress.dart';
import 'package:gallery/src/widgets/notifiers/notes_visibility.dart';

import '../../interfaces/cell.dart';
import '../notifiers/filter.dart';
import '../notifiers/filter_value.dart';
import '../notifiers/focus.dart';
import '../notifiers/tag_refresh.dart';

class WrapImageViewNotifiers<T extends Cell> extends StatelessWidget {
  final void Function() onTagRefresh;
  final FilterNotifierData filterData;
  final T currentCell;
  final InheritedWidget Function(Widget child)? registerNotifiers;
  final Widget child;
  final bool appBarShown;
  final bool notesExtended;
  final double progress;

  const WrapImageViewNotifiers(
      {super.key,
      required this.filterData,
      required this.registerNotifiers,
      required this.onTagRefresh,
      required this.notesExtended,
      required this.progress,
      required this.appBarShown,
      required this.currentCell,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return TagRefreshNotifier(
        notify: onTagRefresh,
        child: FilterValueNotifier(
          notifier: filterData.searchController,
          child: FilterNotifier(
              data: filterData,
              child: FocusNotifier(
                notifier: filterData.searchFocus,
                focusMain: filterData.focusMain,
                child: NotesVisibilityNotifier(
                    isExtended: notesExtended,
                    child: CurrentCellNotifier(
                      cell: currentCell,
                      child: LoadingProgressNotifier(
                          progress: progress,
                          child: AppBarVisibilityNotifier(
                              isShown: appBarShown,
                              child: registerNotifiers == null
                                  ? child
                                  : registerNotifiers!(child))),
                    )),
              )),
        ));
  }
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

class GridRefreshingStatus<T extends CellBase> {
  GridRefreshingStatus(
    int initalCellCount,
    this._reachedEnd, {
    required this.clearRefresh,
    this.next,
  }) : mutation = DefaultMutationInterface(initalCellCount);

  final GridMutationInterface mutation;

  /// [next] gets called when the grid is scrolled around the end of the viewport.
  /// If this is null, then the grid is assumed to be not able to incrementally add posts
  /// by scrolling at the near end of the viewport.
  final Future<int> Function()? next;

  final GridRefreshType clearRefresh;

  final bool Function() _reachedEnd;

  bool get reachedEnd => _reachedEnd();
  Future<int>? updateProgress;

  Object? refreshingError;

  void dispose() {
    mutation.dispose();
    updateProgress?.ignore();
  }

  Future<int> refresh() {
    if (updateProgress != null) {
      return Future.value(mutation.cellCount);
    }

    final refresh = clearRefresh;
    switch (refresh) {
      case SynchronousGridRefresh():
        mutation.cellCount = refresh.refresh();

        return Future.value(mutation.cellCount);
      case AsyncGridRefresh():
        refreshingError = null;
        mutation.isRefreshing = true;
        mutation.cellCount = 0;

        updateProgress = refresh.refresh();

        return _saveOrWait(updateProgress!);
      case RetainedGridRefresh():
        refresh.refresh();

        return Future.value(0);
    }
  }

  Future<int> onNearEnd() {
    if (updateProgress != null ||
        next == null ||
        mutation.isRefreshing ||
        reachedEnd) {
      return Future.value(mutation.cellCount);
    }

    updateProgress = next!();
    mutation.isRefreshing = true;

    return _saveOrWait(updateProgress!);
  }

  Future<int> _saveOrWait(Future<int> f) async {
    try {
      mutation.cellCount = await f;
    } catch (e) {
      refreshingError = e;
    }

    mutation.isRefreshing = false;
    updateProgress = null;

    return mutation.cellCount;
  }
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_refresh_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';

class GridRefreshingStatus<T extends Cell> {
  GridRefreshingStatus(
    int initalCellCount,
    this._reachedEnd,
  ) : mutation = DefaultMutationInterface(initalCellCount);

  void dispose() {
    mutation.dispose();
    updateProgress?.ignore();
  }

  final GridMutationInterface<T> mutation;

  final bool Function() _reachedEnd;

  bool get reachedEnd => _reachedEnd();
  Future<int>? updateProgress;

  Object? refreshingError;

  Future<int> refresh(GridFunctionality<T> functionality) {
    if (updateProgress != null) {
      return Future.value(mutation.cellCount);
    }

    final refresh = functionality.refresh;
    switch (refresh) {
      case SynchronousGridRefresh():
        mutation.cellCount = refresh.refresh();

        return Future.value(mutation.cellCount);
      case AsyncGridRefresh():
        updateProgress = refresh.refresh();

        refreshingError = null;
        mutation.isRefreshing = true;
        mutation.cellCount = 0;

        return _saveOrWait(updateProgress!, functionality);
      case RetainedGridRefresh():
        refresh.refresh();

        return Future.value(0);
    }
  }

  Future<int> onNearEnd(GridFunctionality<T> functionality) async {
    if (updateProgress != null ||
        functionality.loadNext == null ||
        mutation.isRefreshing ||
        reachedEnd) {
      return Future.value(mutation.cellCount);
    }

    updateProgress = functionality.loadNext!();
    mutation.isRefreshing = true;

    return _saveOrWait(updateProgress!, functionality);
  }

  Future<int> _saveOrWait(
      Future<int> f, GridFunctionality<T> functionality) async {
    final refreshBehaviour = functionality.refreshBehaviour;
    switch (refreshBehaviour) {
      case DefaultGridRefreshBehaviour():
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
}

// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'package:gallery/src/interfaces/filtering/sorting_mode.dart';

abstract interface class DataTransformer<T> {
  Set<FilteringMode> get capabilityFiltering;
  Set<SortingMode> get capabilitySorting;

  FilteringMode get currentFiltering;
  SortingMode get currentSoring;

  T transformCell(T elem);
  void transformStatusCallback(void Function(int count) f);

  void setSortingMode(SortingMode sorting);
  void setFilteringMode(FilteringMode filtering);

  void reset();

  const DataTransformer();
}

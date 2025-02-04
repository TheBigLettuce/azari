// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/filtering_mode.dart";

/// Generic way of dealing with persistent or not data.
abstract class SourceStorage<K, V> extends ReadOnlyStorage<K, V> {
  const SourceStorage();

  /// [reversed] might not reverse anything and just return [this].
  Iterable<V> get reversed;

  /// [trySorted] might not sort anything and just return [this].
  Iterable<V> trySorted(SortingMode sort);

  void add(V e, [bool silent = false]);

  /// [addAll] should notify subscriptions if [l] is empty, if possible.
  void addAll(Iterable<V> l, [bool silent = false]);

  List<V> removeAll(Iterable<K> idx, [bool silent = false]);

  void clear([bool silent = false]);

  void destroy();

  void operator []=(K index, V value);
}

abstract class ReadOnlyStorage<K, V> with Iterable<V> {
  const ReadOnlyStorage();

  int get count;

  Stream<int> get countEvents;

  V? get(K idx);

  V operator [](K index);

  StreamSubscription<int> watch(void Function(int) f, [bool fire = false]);
}

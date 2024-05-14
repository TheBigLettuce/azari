// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class FavoriteFileService {
  int get count;

  int get thumbnail;

  Map<int, bool> get cachedValues;

  bool isEmpty();
  bool isNotEmpty();

  bool isFavorite(int id);

  List<int> getAll({required int offset, required int limit});

  void addAll(List<int> ids);

  void deleteAll(List<int> ids);
}

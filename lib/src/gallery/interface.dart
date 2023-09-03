// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/cell/cell.dart';

abstract class GalleryAPIFiles<ExtraFiles, F extends Cell> {
  F directCell(int i);

  Future<int> refresh();
  ExtraFiles getExtra();

  void close();
}

abstract class GalleryAPIDirectories<Extra, ExtraFiles, T extends Cell,
    F extends Cell> {
  T directCell(int i);

  Future<int> refresh();
  Extra getExtra();
  GalleryAPIFiles<ExtraFiles, F> files(T d);

  void close();
}

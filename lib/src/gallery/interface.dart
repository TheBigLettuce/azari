// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/cell/cell.dart';

abstract class GalleryAPIFilesReadWrite<ExtraFiles, F extends Cell>
    implements GalleryAPIFilesRead<ExtraFiles, F>, GalleryAPIFilesWrite<F> {}

abstract class GalleryAPIFilesRead<ExtraFiles, F extends Cell> {
  F directCell(int i);

  Future<int> refresh();
  ExtraFiles getExtra();

  void close();
}

abstract class GalleryAPIFilesWrite<F extends Cell> {
  Future uploadFiles(List<PlatformFile> l, void Function() onDone);
  Future deleteFiles(List<F> f, void Function() onDone);
}

abstract class GalleryAPIReadWrite<Extra, ExtraFiles, T extends Cell,
        F extends Cell>
    implements GalleryAPIRead<Extra, ExtraFiles, T, F>, GalleryAPIWrite<T> {
  GalleryAPIFilesReadWrite<ExtraFiles, F> imagesReadWrite(T d);
}

abstract class GalleryAPIRead<Extra, ExtraFiles, T extends Cell,
    F extends Cell> {
  T directCell(int i);

  Future<int> refresh();
  Extra getExtra();
  GalleryAPIFilesRead<ExtraFiles, F> imagesRead(T d);

  void close();
}

abstract class GalleryAPIWrite<T extends Cell> {
  Future modify(T old, T newd);
  Future delete(T d);
  Future newDirectory(String path, void Function() onDone);
}

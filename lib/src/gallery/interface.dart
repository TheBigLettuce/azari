// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/cell/cell.dart';

class Result<T extends Cell> {
  final int count;
  final T Function(int i) cell;
  const Result(this.cell, this.count);
}

abstract class GalleryAPIFilesReadWrite<ExtraFiles, F extends Cell<A>, A>
    implements
        GalleryAPIFilesRead<ExtraFiles, F, A>,
        GalleryAPIFilesWrite<F, A> {}

abstract class GalleryAPIFilesRead<ExtraFiles, F extends Cell<A>, A> {
  F directCell(int i);

  Future<int> refresh();
  ExtraFiles getExtra();

  void close();
}

abstract class GalleryAPIFilesWrite<F extends Cell<A>, A> {
  Future uploadFiles(List<PlatformFile> l, void Function() onDone);
  Future deleteFiles(List<A> f, void Function() onDone);
}

abstract class GalleryAPIReadWrite<Extra, ExtraFiles, T extends Cell<B>, B,
        F extends Cell<A>, A>
    implements
        GalleryAPIRead<Extra, ExtraFiles, T, B, F, A>,
        GalleryAPIWrite<T, B> {
  GalleryAPIFilesReadWrite<ExtraFiles, F, A> imagesReadWrite(T d);
}

abstract class GalleryAPIRead<Extra, ExtraFiles, T extends Cell<B>, B,
    F extends Cell<A>, A> {
  T directCell(int i);

  Future<int> refresh();
  Extra getExtra();
  GalleryAPIFilesRead<ExtraFiles, F, A> imagesRead(T d);

  void close();
}

abstract class GalleryAPIWrite<T extends Cell<B>, B> {
  Future modify(T old, T newd);
  Future delete(T d);
  Future newDirectory(String path, void Function() onDone);
}

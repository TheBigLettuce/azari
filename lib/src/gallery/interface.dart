// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gallery/src/cell/cell.dart';
import 'package:gallery/src/schemas/directory.dart';
import 'package:gallery/src/schemas/directory_file.dart';

class Result<T extends Cell> {
  final int count;
  final T Function(int i) cell;
  const Result(this.cell, this.count);
}

abstract class GalleryAPIFiles<F extends Cell<A>, A> {
  bool get reachedEnd;

  //Future<Result<DirectoryFile>> nextImages();
  Future<Result<F>> refresh();

  Result<F> filter(String s);
  void resetFilter();

  Future delete(F f);
  Future uploadFiles(List<PlatformFile> l, void Function() onDone);
  Future deleteFiles(List<A> f, void Function() onDone);

  void close();
}

abstract class GalleryAPI<T extends Cell<B>, B, F extends Cell<A>, A> {
  Dio get client;

  Future<Result<T>> directories();
  GalleryAPIFiles<F, A> images(T d);

  Future modify(T old, T newd);
  Future setThumbnail(String newThumb, T d);
  Future delete(T d);
  Future newDirectory(String path, void Function() onDone);

  void close();
}

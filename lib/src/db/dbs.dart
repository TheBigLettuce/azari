// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'initalize_db.dart';

class Dbs {
  final Isar main;
  final Isar? thumbnail;
  final Isar blacklisted;

  final String directory;
  final String temporaryDbDir;
  final String temporaryImagesDir;

  String get appStorageDir => directory;

  void clearTemporaryImages() {
    io.Directory(temporaryImagesDir)
      ..createSync()
      ..deleteSync(recursive: true)
      ..createSync();
  }

  const Dbs._(
      {required this.blacklisted,
      required this.directory,
      required this.main,
      required this.temporaryDbDir,
      required this.temporaryImagesDir,
      required this.thumbnail});

  static Dbs get g => _dbs;
}

late final Dbs _dbs;

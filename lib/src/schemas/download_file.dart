// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

part 'download_file.g.dart';

@collection
class File {
  Id? id;

  @Index(unique: true, replace: true)
  String url;
  @Index(unique: true, replace: true)
  String name;

  DateTime date;

  String site;

  bool isFailed;

  bool inProgress;

  bool isOnHold() => isFailed == false && inProgress == false;

  File inprogress() => File(url, true, false, site, name, id: id);
  File failed() => File(url, false, true, site, name, id: id);
  File onHold() => File(url, false, false, site, name, id: id);

  File.d(this.url, this.site, this.name, {this.id})
      : inProgress = true,
        isFailed = false,
        date = DateTime.now();

  File(this.url, this.inProgress, this.isFailed, this.site, this.name,
      {this.id})
      : date = DateTime.now();
}

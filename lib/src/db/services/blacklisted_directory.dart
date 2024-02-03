// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/gallery/blacklisted_directory.dart';

class BlacklistedDirectoryService {
  StreamSubscription<void>? _watcher;

  void watch(void Function(void) f, [bool fire = true]) {
    _watcher ??= Dbs.g.blacklisted.blacklistedDirectorys
        .watchLazy(fireImmediately: fire)
        .listen(f);
  }

  void dispose() {
    _watcher?.cancel();
  }

  void clear() => Dbs.g.blacklisted
      .writeTxnSync(() => Dbs.g.blacklisted.blacklistedDirectorys.clearSync());

  void deleteAll(List<String> bucketIds) {
    Dbs.g.blacklisted.writeTxnSync(() {
      return Dbs.g.blacklisted.blacklistedDirectorys
          .deleteAllByBucketIdSync(bucketIds);
    });
  }
}

// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/services/impl_table/io.dart";
import "package:isar/isar.dart";

part "directory_metadata.g.dart";

const int _sticky = 0x0001;
const int _blur = 0x0002;
const int _requireAuth = 0x0004;

@collection
class IsarDirectoryMetadata implements $DirectoryMetadata {
  const IsarDirectoryMetadata({
    required this.isarId,
    required this.categoryName,
    required this.time,
    required this.flags,
  });

  const IsarDirectoryMetadata.noIdFlags({
    required this.categoryName,
    required this.time,
  })  : isarId = null,
        flags = 0;

  static int makeFlags({
    required bool requireAuth,
    required bool sticky,
    required bool blur,
  }) {
    var ret = 0;

    if (requireAuth) {
      ret |= _requireAuth;
    }

    if (sticky) {
      ret |= _sticky;
    }

    if (blur) {
      ret |= _blur;
    }

    return ret;
  }

  @override
  @ignore
  bool get requireAuth => (flags & _requireAuth) == _requireAuth;

  @override
  @ignore
  bool get sticky => (flags & _sticky) == _sticky;

  @override
  @ignore
  bool get blur => (flags & _blur) == _blur;

  final Id? isarId;

  @override
  @Index(unique: true, replace: true)
  final String categoryName;

  @Index()
  final int flags;

  @override
  @Index()
  final DateTime time;

  @override
  IsarDirectoryMetadata copyBools({
    bool? blur,
    bool? sticky,
    bool? requireAuth,
  }) {
    final blurValue =
        (blur != null && blur) || (blur == null && this.blur) ? _blur : 0;
    final stickyValue =
        (sticky != null && sticky) || (sticky == null && this.sticky)
            ? _sticky
            : 0;
    final requireValue = (requireAuth != null && requireAuth) ||
            (requireAuth == null && this.requireAuth)
        ? _requireAuth
        : 0;

    return IsarDirectoryMetadata(
      isarId: isarId,
      categoryName: categoryName,
      time: time,
      flags: blurValue | stickyValue | requireValue,
    );
  }
}

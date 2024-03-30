// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/main.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/tags/tags.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:isar/isar.dart';
import 'package:local_auth/local_auth.dart';

part 'directory_metadata.g.dart';

@collection
class DirectoryMetadata {
  const DirectoryMetadata(
    this.categoryName,
    this.time, {
    required this.blur,
    required this.sticky,
    required this.requireAuth,
  });

  Id get isarId => fastHash(categoryName);

  @Index(unique: true, replace: true)
  final String categoryName;
  @Index()
  final DateTime time;

  final bool blur;
  final bool requireAuth;
  final bool sticky;

  static SegmentCapability caps(String specialLabel) =>
      _DirectoryMetadataCap(specialLabel);

  static DirectoryMetadata? get(String id) =>
      Dbs.g.blacklisted.directoryMetadatas.getByCategoryNameSync(id);

  static Future<bool> canAuth(String id, String reason) async {
    if (!canAuthBiometric) {
      return true;
    }

    if (DirectoryMetadata.get(id)?.requireAuth ?? false) {
      final success =
          await LocalAuthentication().authenticate(localizedReason: reason);
      if (!success) {
        return false;
      }
    }

    return true;
  }

  DirectoryMetadata copyBools({
    bool? blur,
    bool? sticky,
    bool? requireAuth,
  }) {
    return DirectoryMetadata(
      categoryName,
      time,
      blur: blur ?? this.blur,
      sticky: sticky ?? this.sticky,
      requireAuth: requireAuth ?? this.requireAuth,
    );
  }

  void save() {
    Dbs.g.blacklisted.writeTxnSync(
      () {
        Dbs.g.blacklisted.directoryMetadatas.putByCategoryNameSync(this);
      },
    );
  }

  static void add(
    String id, {
    required bool blur,
    required bool auth,
    required bool sticky,
  }) {
    if (id.isEmpty) {
      return;
    }

    Dbs.g.blacklisted.writeTxnSync(
      () {
        Dbs.g.blacklisted.directoryMetadatas
            .putByCategoryNameSync(DirectoryMetadata(
          id,
          DateTime.now(),
          blur: blur,
          requireAuth: auth,
          sticky: sticky,
        ));
      },
    );
  }
}

class _DirectoryMetadataCap implements SegmentCapability {
  const _DirectoryMetadataCap(this.specialLabel);

  final String specialLabel;

  @override
  Set<SegmentModifier> modifiersFor(String seg) {
    if (seg.isEmpty) {
      return const {};
    }

    if (seg == "Booru" || seg == specialLabel) {
      return const {SegmentModifier.sticky};
    }

    final m = DirectoryMetadata.get(seg);

    if (m == null) {
      return const {};
    }

    final set = <SegmentModifier>{};

    if (m.blur) {
      set.add(SegmentModifier.blur);
    }

    if (m.requireAuth) {
      set.add(SegmentModifier.auth);
    }

    if (m.sticky) {
      set.add(SegmentModifier.sticky);
    }

    return set;
  }

  @override
  void addModifiers(List<String> segments, Set<SegmentModifier> m) {
    segments = segments
        .where((element) => element != "Booru" && element != specialLabel)
        .toList();

    if (segments.isEmpty || m.isEmpty) {
      return;
    }

    final l = Dbs.g.blacklisted.directoryMetadatas
        .getAllByCategoryNameSync(segments)
        .indexed
        .map(
          (element) =>
              element.$2 ??
              DirectoryMetadata(segments[element.$1], DateTime.now(),
                  blur: false, sticky: false, requireAuth: false),
        );
    final toUpdate = <DirectoryMetadata>[];

    for (var seg in l) {
      for (final e in m) {
        switch (e) {
          case SegmentModifier.blur:
            seg = seg.copyBools(blur: true);
          case SegmentModifier.auth:
            seg = seg.copyBools(requireAuth: true);
          case SegmentModifier.sticky:
            seg = seg.copyBools(sticky: true);
        }
      }

      toUpdate.add(seg);
    }

    Dbs.g.blacklisted.writeTxnSync(() => Dbs.g.blacklisted.directoryMetadatas
        .putAllByCategoryNameSync(toUpdate));
  }

  @override
  void removeModifiers(List<String> segments, Set<SegmentModifier> m) {
    segments = segments
        .where((element) => element != "Booru" && element != specialLabel)
        .toList();

    if (segments.isEmpty || m.isEmpty) {
      return;
    }

    final l = Dbs.g.blacklisted.directoryMetadatas
        .getAllByCategoryNameSync(segments)
        .indexed
        .map((e) =>
            e.$2 ??
            DirectoryMetadata(
              segments[e.$1],
              DateTime.now(),
              blur: false,
              sticky: false,
              requireAuth: false,
            ));
    final toUpdate = <DirectoryMetadata>[];

    for (var seg in l) {
      for (final e in m) {
        switch (e) {
          case SegmentModifier.blur:
            seg = seg.copyBools(blur: false);
          case SegmentModifier.auth:
            seg = seg.copyBools(requireAuth: false);
          case SegmentModifier.sticky:
            seg = seg.copyBools(sticky: false);
        }
      }

      toUpdate.add(seg);
    }

    Dbs.g.blacklisted.writeTxnSync(() => Dbs.g.blacklisted.directoryMetadatas
        .putAllByCategoryNameSync(toUpdate));
  }
}

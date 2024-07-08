// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension DirectoryMetadataDataExt on DirectoryMetadata {
  void save() => _currentDb.directoryMetadata.add(this);
}

abstract interface class DirectoryMetadataService implements ServiceMarker {
  SegmentCapability caps(String specialLabel);

  DirectoryMetadata? get(String id);
  DirectoryMetadata getOrCreate(String id);

  Future<bool> canAuth(String id, String reason);

  void add(DirectoryMetadata data);

  void put(
    String id, {
    required bool blur,
    required bool auth,
    required bool sticky,
  });

  StreamSubscription<void> watch(void Function(void) f, [bool fire = false]);
}

@immutable
abstract class DirectoryMetadata {
  const DirectoryMetadata();

  String get categoryName;
  DateTime get time;

  bool get blur;
  bool get requireAuth;
  bool get sticky;

  DirectoryMetadata copyBools({
    bool? blur,
    bool? sticky,
    bool? requireAuth,
  });
}

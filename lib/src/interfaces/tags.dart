// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import '../db/schemas/tags.dart';

/// Tag search history.
/// Used for both for the recent tags and the excluded.
abstract class BooruTagging {
  /// Get the current tags.
  /// Last added first.
  List<Tag> get();

  /// Add the [tag] to the DB.
  /// Updates the added time if already exist.
  void add(Tag tag);

  /// Delete the [tag] from the DB.
  void delete(Tag tag);

  /// Delete all the tags from the DB.
  void clear();

  const BooruTagging();
}

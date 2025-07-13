// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/services/services.dart";
import "package:isar/isar.dart";

part "accounts.g.dart";

@collection
class IsarAccounts extends AccountsData {
  const IsarAccounts({
    required this.danbooruApiKey,
    required this.danbooruUsername,
    required this.gelbooruApiKey,
    required this.gelbooruUserId,
  });

  Id get id => 0;

  @override
  final String danbooruApiKey;

  @override
  final String danbooruUsername;

  @override
  final String gelbooruApiKey;

  @override
  final String gelbooruUserId;

  @override
  IsarAccounts copy({
    String? danbooruApiKey,
    String? danbooruUsername,
    String? gelbooruApiKey,
    String? gelbooruUserId,
  }) => IsarAccounts(
    danbooruApiKey: danbooruApiKey ?? this.danbooruApiKey,
    danbooruUsername: danbooruUsername ?? this.danbooruUsername,
    gelbooruApiKey: gelbooruApiKey ?? this.gelbooruApiKey,
    gelbooruUserId: gelbooruUserId ?? this.gelbooruUserId,
  );
}

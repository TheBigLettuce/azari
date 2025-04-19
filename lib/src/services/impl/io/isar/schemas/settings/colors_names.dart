// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/services/impl/io.dart";
import "package:azari/src/services/services.dart";
import "package:isar/isar.dart";

part "colors_names.g.dart";

@collection
class IsarColorsNamesData
    with ColorsNamesDataCopyImpl
    implements $ColorsNamesData {
  const IsarColorsNamesData({
    required this.red,
    required this.blue,
    required this.yellow,
    required this.green,
    required this.purple,
    required this.orange,
    required this.pink,
    required this.white,
    required this.brown,
    required this.black,
  });

  Id get id => 0;

  @override
  final String red;
  @override
  final String blue;
  @override
  final String yellow;

  @override
  final String green;
  @override
  final String purple;
  @override
  final String orange;

  @override
  final String pink;
  @override
  final String white;
  @override
  final String brown;

  @override
  final String black;
}

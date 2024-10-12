// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "manga_dex_entries.dart";

@JsonSerializable()
class _MangaEntry with MangaEntry, DefaultBuildCellImpl {
  const _MangaEntry({
    required this.id,
    required this.relationships,
    required this.attributes,
  });

  factory _MangaEntry.fromJson(Map<String, dynamic> json) =>
      _$MangaEntryFromJson(json);

  @override
  @MangaDexIdConverter()
  @JsonKey(name: "id")
  final MangaStringId id;

  @JsonKey(name: "relationships")
  final List<_Relationships> relationships;

  @JsonKey(name: "attributes")
  final _Attributes attributes;

  @override
  List<AnimeId> get animeIds => const [];

  @override
  List<MangaGenre> get genres => attributes.tags
      .map(
        (e) => MangaGenre(
          id: MangaStringId(e.id),
          name: _tagOrFirst("en", e.attributes.names),
        ),
      )
      .toList();

  @override
  List<MangaRelation> get relations => relationships
      .where((element) => element.type == "manga")
      .map(
        (e) => MangaRelation(
          id: MangaStringId(e.id),
          name: _tagOrFirst("en", e.attributes?.title),
        ),
      )
      .toList();

  @override
  String get demographics => attributes.demographics ?? "";

  @override
  String get status => attributes.status;

  @override
  AnimeSafeMode get safety => attributes.contentRating;

  @override
  MangaMeta get site => MangaMeta.mangaDex;

  @override
  String get synopsis => _tagOrFirst("en", attributes.descriptions);

  @override
  String get thumbUrl => _constructImageUrl(
        id: id.id,
        thumb: true,
        fileName: _coverArt(),
      );

  @override
  String get imageUrl =>
      _constructImageUrl(id: id.id, thumb: false, fileName: _coverArt());

  @override
  String get title => attributes.titlesExtra["ja-ro"] ?? titleEnglish;

  @override
  String get titleEnglish =>
      attributes.titles["en"] ?? attributes.titlesExtra["en"] ?? "";

  @override
  String get titleJapanese =>
      attributes.titlesExtra[attributes.originalLanguage] ?? title;

  @override
  List<String> get titleSynonyms => attributes.titlesExtra.values.toList();

  @override
  int get volumes => attributes.volumes;

  @override
  int get year => attributes.year ?? -1;

  String _tagOrFirst(String tag, Map<String, String>? m) {
    if (m == null) {
      return "";
    }

    final en = m[tag];
    if (en == null) {
      return m.isNotEmpty ? m.values.first : "";
    }

    return en;
  }

  String _coverArt() => relationships
      .where((element) => element.type == "cover_art")
      .first
      .attributes!
      .filename!;

  static String _constructImageUrl({
    required String id,
    required bool thumb,
    required String fileName,
  }) =>
      switch (thumb) {
        true => "https://uploads.mangadex.org/covers/$id/$fileName.256.jpg",
        false => "https://uploads.mangadex.org/covers/$id/$fileName",
      };
}

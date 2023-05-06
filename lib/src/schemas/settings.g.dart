// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSettingsCollection on Isar {
  IsarCollection<Settings> get settings => this.collection();
}

const SettingsSchema = CollectionSchema(
  name: r'Settings',
  id: -8656046621518759136,
  properties: {
    r'booruDefault': PropertySchema(
      id: 0,
      name: r'booruDefault',
      type: IsarType.bool,
    ),
    r'enableGallery': PropertySchema(
      id: 1,
      name: r'enableGallery',
      type: IsarType.bool,
    ),
    r'path': PropertySchema(
      id: 2,
      name: r'path',
      type: IsarType.string,
    ),
    r'quality': PropertySchema(
      id: 3,
      name: r'quality',
      type: IsarType.byte,
      enumMap: _SettingsqualityEnumValueMap,
    ),
    r'selectedBooru': PropertySchema(
      id: 4,
      name: r'selectedBooru',
      type: IsarType.byte,
      enumMap: _SettingsselectedBooruEnumValueMap,
    )
  },
  estimateSize: _settingsEstimateSize,
  serialize: _settingsSerialize,
  deserialize: _settingsDeserialize,
  deserializeProp: _settingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _settingsGetId,
  getLinks: _settingsGetLinks,
  attach: _settingsAttach,
  version: '3.1.0+1',
);

int _settingsEstimateSize(
  Settings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.path.length * 3;
  return bytesCount;
}

void _settingsSerialize(
  Settings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.booruDefault);
  writer.writeBool(offsets[1], object.enableGallery);
  writer.writeString(offsets[2], object.path);
  writer.writeByte(offsets[3], object.quality.index);
  writer.writeByte(offsets[4], object.selectedBooru.index);
}

Settings _settingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Settings(
    booruDefault: reader.readBool(offsets[0]),
    enableGallery: reader.readBool(offsets[1]),
    path: reader.readString(offsets[2]),
    quality: _SettingsqualityValueEnumMap[reader.readByteOrNull(offsets[3])] ??
        DisplayQuality.original,
    selectedBooru:
        _SettingsselectedBooruValueEnumMap[reader.readByteOrNull(offsets[4])] ??
            Booru.gelbooru,
  );
  object.id = id;
  return object;
}

P _settingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (_SettingsqualityValueEnumMap[reader.readByteOrNull(offset)] ??
          DisplayQuality.original) as P;
    case 4:
      return (_SettingsselectedBooruValueEnumMap[
              reader.readByteOrNull(offset)] ??
          Booru.gelbooru) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SettingsqualityEnumValueMap = {
  'original': 0,
  'sample': 1,
};
const _SettingsqualityValueEnumMap = {
  0: DisplayQuality.original,
  1: DisplayQuality.sample,
};
const _SettingsselectedBooruEnumValueMap = {
  'gelbooru': 0,
  'danbooru': 1,
};
const _SettingsselectedBooruValueEnumMap = {
  0: Booru.gelbooru,
  1: Booru.danbooru,
};

Id _settingsGetId(Settings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _settingsGetLinks(Settings object) {
  return [];
}

void _settingsAttach(IsarCollection<dynamic> col, Id id, Settings object) {
  object.id = id;
}

extension SettingsQueryWhereSort on QueryBuilder<Settings, Settings, QWhere> {
  QueryBuilder<Settings, Settings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SettingsQueryWhere on QueryBuilder<Settings, Settings, QWhereClause> {
  QueryBuilder<Settings, Settings, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SettingsQueryFilter
    on QueryBuilder<Settings, Settings, QFilterCondition> {
  QueryBuilder<Settings, Settings, QAfterFilterCondition> booruDefaultEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'booruDefault',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> enableGalleryEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enableGallery',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'path',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'path',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'path',
        value: '',
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> pathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'path',
        value: '',
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> qualityEqualTo(
      DisplayQuality value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quality',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> qualityGreaterThan(
    DisplayQuality value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quality',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> qualityLessThan(
    DisplayQuality value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quality',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> qualityBetween(
    DisplayQuality lower,
    DisplayQuality upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quality',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> selectedBooruEqualTo(
      Booru value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedBooru',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      selectedBooruGreaterThan(
    Booru value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedBooru',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> selectedBooruLessThan(
    Booru value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedBooru',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> selectedBooruBetween(
    Booru lower,
    Booru upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedBooru',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SettingsQueryObject
    on QueryBuilder<Settings, Settings, QFilterCondition> {}

extension SettingsQueryLinks
    on QueryBuilder<Settings, Settings, QFilterCondition> {}

extension SettingsQuerySortBy on QueryBuilder<Settings, Settings, QSortBy> {
  QueryBuilder<Settings, Settings, QAfterSortBy> sortByBooruDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'booruDefault', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByBooruDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'booruDefault', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByEnableGallery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableGallery', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByEnableGalleryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableGallery', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByQuality() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quality', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByQualityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quality', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySelectedBooru() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedBooru', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySelectedBooruDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedBooru', Sort.desc);
    });
  }
}

extension SettingsQuerySortThenBy
    on QueryBuilder<Settings, Settings, QSortThenBy> {
  QueryBuilder<Settings, Settings, QAfterSortBy> thenByBooruDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'booruDefault', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByBooruDefaultDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'booruDefault', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByEnableGallery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableGallery', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByEnableGalleryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enableGallery', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByQuality() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quality', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByQualityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quality', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySelectedBooru() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedBooru', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySelectedBooruDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedBooru', Sort.desc);
    });
  }
}

extension SettingsQueryWhereDistinct
    on QueryBuilder<Settings, Settings, QDistinct> {
  QueryBuilder<Settings, Settings, QDistinct> distinctByBooruDefault() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'booruDefault');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByEnableGallery() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enableGallery');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'path', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByQuality() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quality');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctBySelectedBooru() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedBooru');
    });
  }
}

extension SettingsQueryProperty
    on QueryBuilder<Settings, Settings, QQueryProperty> {
  QueryBuilder<Settings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations> booruDefaultProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'booruDefault');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations> enableGalleryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enableGallery');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations> pathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'path');
    });
  }

  QueryBuilder<Settings, DisplayQuality, QQueryOperations> qualityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quality');
    });
  }

  QueryBuilder<Settings, Booru, QQueryOperations> selectedBooruProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedBooru');
    });
  }
}

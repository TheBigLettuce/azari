// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secondary_grid.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSecondaryGridCollection on Isar {
  IsarCollection<SecondaryGrid> get secondaryGrids => this.collection();
}

const SecondaryGridSchema = CollectionSchema(
  name: r'SecondaryGrid',
  id: -6802639819875198684,
  properties: {
    r'page': PropertySchema(
      id: 0,
      name: r'page',
      type: IsarType.long,
    ),
    r'scrollPositionGrid': PropertySchema(
      id: 1,
      name: r'scrollPositionGrid',
      type: IsarType.double,
    ),
    r'scrollPositionTags': PropertySchema(
      id: 2,
      name: r'scrollPositionTags',
      type: IsarType.double,
    ),
    r'selectedPost': PropertySchema(
      id: 3,
      name: r'selectedPost',
      type: IsarType.long,
    ),
    r'tags': PropertySchema(
      id: 4,
      name: r'tags',
      type: IsarType.string,
    )
  },
  estimateSize: _secondaryGridEstimateSize,
  serialize: _secondaryGridSerialize,
  deserialize: _secondaryGridDeserialize,
  deserializeProp: _secondaryGridDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _secondaryGridGetId,
  getLinks: _secondaryGridGetLinks,
  attach: _secondaryGridAttach,
  version: '3.1.0+1',
);

int _secondaryGridEstimateSize(
  SecondaryGrid object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.tags.length * 3;
  return bytesCount;
}

void _secondaryGridSerialize(
  SecondaryGrid object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.page);
  writer.writeDouble(offsets[1], object.scrollPositionGrid);
  writer.writeDouble(offsets[2], object.scrollPositionTags);
  writer.writeLong(offsets[3], object.selectedPost);
  writer.writeString(offsets[4], object.tags);
}

SecondaryGrid _secondaryGridDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SecondaryGrid(
    reader.readString(offsets[4]),
    reader.readDoubleOrNull(offsets[2]),
    reader.readLongOrNull(offsets[3]),
    reader.readDouble(offsets[1]),
    page: reader.readLongOrNull(offsets[0]),
  );
  object.id = id;
  return object;
}

P _secondaryGridDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _secondaryGridGetId(SecondaryGrid object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _secondaryGridGetLinks(SecondaryGrid object) {
  return [];
}

void _secondaryGridAttach(
    IsarCollection<dynamic> col, Id id, SecondaryGrid object) {
  object.id = id;
}

extension SecondaryGridQueryWhereSort
    on QueryBuilder<SecondaryGrid, SecondaryGrid, QWhere> {
  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SecondaryGridQueryWhere
    on QueryBuilder<SecondaryGrid, SecondaryGrid, QWhereClause> {
  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterWhereClause> idBetween(
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

extension SecondaryGridQueryFilter
    on QueryBuilder<SecondaryGrid, SecondaryGrid, QFilterCondition> {
  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      pageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'page',
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      pageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'page',
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition> pageEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'page',
        value: value,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      pageGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'page',
        value: value,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      pageLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'page',
        value: value,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition> pageBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'page',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionGridEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scrollPositionGrid',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionGridGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scrollPositionGrid',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionGridLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scrollPositionGrid',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionGridBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scrollPositionGrid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionTagsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scrollPositionTags',
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionTagsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scrollPositionTags',
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionTagsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scrollPositionTags',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionTagsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scrollPositionTags',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionTagsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scrollPositionTags',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      scrollPositionTagsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scrollPositionTags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      selectedPostIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'selectedPost',
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      selectedPostIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'selectedPost',
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      selectedPostEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedPost',
        value: value,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      selectedPostGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedPost',
        value: value,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      selectedPostLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedPost',
        value: value,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      selectedPostBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedPost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition> tagsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      tagsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      tagsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition> tagsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      tagsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      tagsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      tagsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition> tagsMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterFilterCondition>
      tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tags',
        value: '',
      ));
    });
  }
}

extension SecondaryGridQueryObject
    on QueryBuilder<SecondaryGrid, SecondaryGrid, QFilterCondition> {}

extension SecondaryGridQueryLinks
    on QueryBuilder<SecondaryGrid, SecondaryGrid, QFilterCondition> {}

extension SecondaryGridQuerySortBy
    on QueryBuilder<SecondaryGrid, SecondaryGrid, QSortBy> {
  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> sortByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> sortByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      sortByScrollPositionGrid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPositionGrid', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      sortByScrollPositionGridDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPositionGrid', Sort.desc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      sortByScrollPositionTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPositionTags', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      sortByScrollPositionTagsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPositionTags', Sort.desc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      sortBySelectedPost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedPost', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      sortBySelectedPostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedPost', Sort.desc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> sortByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tags', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> sortByTagsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tags', Sort.desc);
    });
  }
}

extension SecondaryGridQuerySortThenBy
    on QueryBuilder<SecondaryGrid, SecondaryGrid, QSortThenBy> {
  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> thenByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> thenByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      thenByScrollPositionGrid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPositionGrid', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      thenByScrollPositionGridDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPositionGrid', Sort.desc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      thenByScrollPositionTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPositionTags', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      thenByScrollPositionTagsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrollPositionTags', Sort.desc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      thenBySelectedPost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedPost', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy>
      thenBySelectedPostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedPost', Sort.desc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> thenByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tags', Sort.asc);
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QAfterSortBy> thenByTagsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tags', Sort.desc);
    });
  }
}

extension SecondaryGridQueryWhereDistinct
    on QueryBuilder<SecondaryGrid, SecondaryGrid, QDistinct> {
  QueryBuilder<SecondaryGrid, SecondaryGrid, QDistinct> distinctByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'page');
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QDistinct>
      distinctByScrollPositionGrid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scrollPositionGrid');
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QDistinct>
      distinctByScrollPositionTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scrollPositionTags');
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QDistinct>
      distinctBySelectedPost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedPost');
    });
  }

  QueryBuilder<SecondaryGrid, SecondaryGrid, QDistinct> distinctByTags(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags', caseSensitive: caseSensitive);
    });
  }
}

extension SecondaryGridQueryProperty
    on QueryBuilder<SecondaryGrid, SecondaryGrid, QQueryProperty> {
  QueryBuilder<SecondaryGrid, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SecondaryGrid, int?, QQueryOperations> pageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'page');
    });
  }

  QueryBuilder<SecondaryGrid, double, QQueryOperations>
      scrollPositionGridProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scrollPositionGrid');
    });
  }

  QueryBuilder<SecondaryGrid, double?, QQueryOperations>
      scrollPositionTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scrollPositionTags');
    });
  }

  QueryBuilder<SecondaryGrid, int?, QQueryOperations> selectedPostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedPost');
    });
  }

  QueryBuilder<SecondaryGrid, String, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }
}

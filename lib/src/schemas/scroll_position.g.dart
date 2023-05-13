// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scroll_position.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetScrollPositionPrimaryCollection on Isar {
  IsarCollection<ScrollPositionPrimary> get scrollPositionPrimarys =>
      this.collection();
}

const ScrollPositionPrimarySchema = CollectionSchema(
  name: r'ScrollPositionPrimary',
  id: 5138468245474928201,
  properties: {
    r'id': PropertySchema(
      id: 0,
      name: r'id',
      type: IsarType.string,
    ),
    r'page': PropertySchema(
      id: 1,
      name: r'page',
      type: IsarType.long,
    ),
    r'pos': PropertySchema(
      id: 2,
      name: r'pos',
      type: IsarType.double,
    ),
    r'tagPos': PropertySchema(
      id: 3,
      name: r'tagPos',
      type: IsarType.double,
    )
  },
  estimateSize: _scrollPositionPrimaryEstimateSize,
  serialize: _scrollPositionPrimarySerialize,
  deserialize: _scrollPositionPrimaryDeserialize,
  deserializeProp: _scrollPositionPrimaryDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _scrollPositionPrimaryGetId,
  getLinks: _scrollPositionPrimaryGetLinks,
  attach: _scrollPositionPrimaryAttach,
  version: '3.1.0+1',
);

int _scrollPositionPrimaryEstimateSize(
  ScrollPositionPrimary object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.id.length * 3;
  return bytesCount;
}

void _scrollPositionPrimarySerialize(
  ScrollPositionPrimary object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.id);
  writer.writeLong(offsets[1], object.page);
  writer.writeDouble(offsets[2], object.pos);
  writer.writeDouble(offsets[3], object.tagPos);
}

ScrollPositionPrimary _scrollPositionPrimaryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ScrollPositionPrimary(
    reader.readDouble(offsets[2]),
    reader.readString(offsets[0]),
    page: reader.readLongOrNull(offsets[1]),
    tagPos: reader.readDoubleOrNull(offsets[3]),
  );
  return object;
}

P _scrollPositionPrimaryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _scrollPositionPrimaryGetId(ScrollPositionPrimary object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _scrollPositionPrimaryGetLinks(
    ScrollPositionPrimary object) {
  return [];
}

void _scrollPositionPrimaryAttach(
    IsarCollection<dynamic> col, Id id, ScrollPositionPrimary object) {}

extension ScrollPositionPrimaryQueryWhereSort
    on QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QWhere> {
  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ScrollPositionPrimaryQueryWhere on QueryBuilder<ScrollPositionPrimary,
    ScrollPositionPrimary, QWhereClause> {
  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ScrollPositionPrimaryQueryFilter on QueryBuilder<
    ScrollPositionPrimary, ScrollPositionPrimary, QFilterCondition> {
  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
          QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
          QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> pageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'page',
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> pageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'page',
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> pageEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'page',
        value: value,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> pageGreaterThan(
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

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> pageLessThan(
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

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> pageBetween(
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

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> posEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pos',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> posGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pos',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> posLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pos',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> posBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pos',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> tagPosIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tagPos',
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> tagPosIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tagPos',
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> tagPosEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tagPos',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> tagPosGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tagPos',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> tagPosLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tagPos',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary,
      QAfterFilterCondition> tagPosBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tagPos',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension ScrollPositionPrimaryQueryObject on QueryBuilder<
    ScrollPositionPrimary, ScrollPositionPrimary, QFilterCondition> {}

extension ScrollPositionPrimaryQueryLinks on QueryBuilder<ScrollPositionPrimary,
    ScrollPositionPrimary, QFilterCondition> {}

extension ScrollPositionPrimaryQuerySortBy
    on QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QSortBy> {
  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      sortByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      sortByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      sortByPos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pos', Sort.asc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      sortByPosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pos', Sort.desc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      sortByTagPos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagPos', Sort.asc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      sortByTagPosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagPos', Sort.desc);
    });
  }
}

extension ScrollPositionPrimaryQuerySortThenBy
    on QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QSortThenBy> {
  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenByPos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pos', Sort.asc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenByPosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pos', Sort.desc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenByTagPos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagPos', Sort.asc);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QAfterSortBy>
      thenByTagPosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tagPos', Sort.desc);
    });
  }
}

extension ScrollPositionPrimaryQueryWhereDistinct
    on QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QDistinct> {
  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QDistinct>
      distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QDistinct>
      distinctByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'page');
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QDistinct>
      distinctByPos() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pos');
    });
  }

  QueryBuilder<ScrollPositionPrimary, ScrollPositionPrimary, QDistinct>
      distinctByTagPos() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tagPos');
    });
  }
}

extension ScrollPositionPrimaryQueryProperty on QueryBuilder<
    ScrollPositionPrimary, ScrollPositionPrimary, QQueryProperty> {
  QueryBuilder<ScrollPositionPrimary, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<ScrollPositionPrimary, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ScrollPositionPrimary, int?, QQueryOperations> pageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'page');
    });
  }

  QueryBuilder<ScrollPositionPrimary, double, QQueryOperations> posProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pos');
    });
  }

  QueryBuilder<ScrollPositionPrimary, double?, QQueryOperations>
      tagPosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tagPos');
    });
  }
}

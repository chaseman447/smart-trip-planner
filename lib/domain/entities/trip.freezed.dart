// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Trip _$TripFromJson(Map<String, dynamic> json) {
  return _Trip.fromJson(json);
}

/// @nodoc
mixin _$Trip {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  List<DayItinerary> get days => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  int get totalTokensUsed => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TripCopyWith<Trip> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripCopyWith<$Res> {
  factory $TripCopyWith(Trip value, $Res Function(Trip) then) =
      _$TripCopyWithImpl<$Res, Trip>;
  @useResult
  $Res call(
      {String id,
      String title,
      DateTime startDate,
      DateTime endDate,
      List<DayItinerary> days,
      DateTime createdAt,
      DateTime? updatedAt,
      int totalTokensUsed});
}

/// @nodoc
class _$TripCopyWithImpl<$Res, $Val extends Trip>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? days = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? totalTokensUsed = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      days: null == days
          ? _value.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<DayItinerary>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalTokensUsed: null == totalTokensUsed
          ? _value.totalTokensUsed
          : totalTokensUsed // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripImplCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$$TripImplCopyWith(
          _$TripImpl value, $Res Function(_$TripImpl) then) =
      __$$TripImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      DateTime startDate,
      DateTime endDate,
      List<DayItinerary> days,
      DateTime createdAt,
      DateTime? updatedAt,
      int totalTokensUsed});
}

/// @nodoc
class __$$TripImplCopyWithImpl<$Res>
    extends _$TripCopyWithImpl<$Res, _$TripImpl>
    implements _$$TripImplCopyWith<$Res> {
  __$$TripImplCopyWithImpl(_$TripImpl _value, $Res Function(_$TripImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? days = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? totalTokensUsed = null,
  }) {
    return _then(_$TripImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      days: null == days
          ? _value._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<DayItinerary>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalTokensUsed: null == totalTokensUsed
          ? _value.totalTokensUsed
          : totalTokensUsed // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TripImpl implements _Trip {
  const _$TripImpl(
      {required this.id,
      required this.title,
      required this.startDate,
      required this.endDate,
      required final List<DayItinerary> days,
      required this.createdAt,
      this.updatedAt,
      this.totalTokensUsed = 0})
      : _days = days;

  factory _$TripImpl.fromJson(Map<String, dynamic> json) =>
      _$$TripImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  final List<DayItinerary> _days;
  @override
  List<DayItinerary> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  @JsonKey()
  final int totalTokensUsed;

  @override
  String toString() {
    return 'Trip(id: $id, title: $title, startDate: $startDate, endDate: $endDate, days: $days, createdAt: $createdAt, updatedAt: $updatedAt, totalTokensUsed: $totalTokensUsed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            const DeepCollectionEquality().equals(other._days, _days) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.totalTokensUsed, totalTokensUsed) ||
                other.totalTokensUsed == totalTokensUsed));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      startDate,
      endDate,
      const DeepCollectionEquality().hash(_days),
      createdAt,
      updatedAt,
      totalTokensUsed);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      __$$TripImplCopyWithImpl<_$TripImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TripImplToJson(
      this,
    );
  }
}

abstract class _Trip implements Trip {
  const factory _Trip(
      {required final String id,
      required final String title,
      required final DateTime startDate,
      required final DateTime endDate,
      required final List<DayItinerary> days,
      required final DateTime createdAt,
      final DateTime? updatedAt,
      final int totalTokensUsed}) = _$TripImpl;

  factory _Trip.fromJson(Map<String, dynamic> json) = _$TripImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  List<DayItinerary> get days;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  int get totalTokensUsed;
  @override
  @JsonKey(ignore: true)
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DayItinerary _$DayItineraryFromJson(Map<String, dynamic> json) {
  return _DayItinerary.fromJson(json);
}

/// @nodoc
mixin _$DayItinerary {
  DateTime get date => throw _privateConstructorUsedError;
  String get summary => throw _privateConstructorUsedError;
  List<ItineraryItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DayItineraryCopyWith<DayItinerary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DayItineraryCopyWith<$Res> {
  factory $DayItineraryCopyWith(
          DayItinerary value, $Res Function(DayItinerary) then) =
      _$DayItineraryCopyWithImpl<$Res, DayItinerary>;
  @useResult
  $Res call({DateTime date, String summary, List<ItineraryItem> items});
}

/// @nodoc
class _$DayItineraryCopyWithImpl<$Res, $Val extends DayItinerary>
    implements $DayItineraryCopyWith<$Res> {
  _$DayItineraryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? summary = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItineraryItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DayItineraryImplCopyWith<$Res>
    implements $DayItineraryCopyWith<$Res> {
  factory _$$DayItineraryImplCopyWith(
          _$DayItineraryImpl value, $Res Function(_$DayItineraryImpl) then) =
      __$$DayItineraryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, String summary, List<ItineraryItem> items});
}

/// @nodoc
class __$$DayItineraryImplCopyWithImpl<$Res>
    extends _$DayItineraryCopyWithImpl<$Res, _$DayItineraryImpl>
    implements _$$DayItineraryImplCopyWith<$Res> {
  __$$DayItineraryImplCopyWithImpl(
      _$DayItineraryImpl _value, $Res Function(_$DayItineraryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? summary = null,
    Object? items = null,
  }) {
    return _then(_$DayItineraryImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ItineraryItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DayItineraryImpl implements _DayItinerary {
  const _$DayItineraryImpl(
      {required this.date,
      required this.summary,
      required final List<ItineraryItem> items})
      : _items = items;

  factory _$DayItineraryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DayItineraryImplFromJson(json);

  @override
  final DateTime date;
  @override
  final String summary;
  final List<ItineraryItem> _items;
  @override
  List<ItineraryItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'DayItinerary(date: $date, summary: $summary, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DayItineraryImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, date, summary, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DayItineraryImplCopyWith<_$DayItineraryImpl> get copyWith =>
      __$$DayItineraryImplCopyWithImpl<_$DayItineraryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DayItineraryImplToJson(
      this,
    );
  }
}

abstract class _DayItinerary implements DayItinerary {
  const factory _DayItinerary(
      {required final DateTime date,
      required final String summary,
      required final List<ItineraryItem> items}) = _$DayItineraryImpl;

  factory _DayItinerary.fromJson(Map<String, dynamic> json) =
      _$DayItineraryImpl.fromJson;

  @override
  DateTime get date;
  @override
  String get summary;
  @override
  List<ItineraryItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$DayItineraryImplCopyWith<_$DayItineraryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ItineraryItem _$ItineraryItemFromJson(Map<String, dynamic> json) {
  return _ItineraryItem.fromJson(json);
}

/// @nodoc
mixin _$ItineraryItem {
  String get time => throw _privateConstructorUsedError;
  String get activity => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get mapUrl => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItineraryItemCopyWith<ItineraryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryItemCopyWith<$Res> {
  factory $ItineraryItemCopyWith(
          ItineraryItem value, $Res Function(ItineraryItem) then) =
      _$ItineraryItemCopyWithImpl<$Res, ItineraryItem>;
  @useResult
  $Res call(
      {String time,
      String activity,
      String location,
      String? description,
      String? mapUrl,
      bool isCompleted});
}

/// @nodoc
class _$ItineraryItemCopyWithImpl<$Res, $Val extends ItineraryItem>
    implements $ItineraryItemCopyWith<$Res> {
  _$ItineraryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? activity = null,
    Object? location = null,
    Object? description = freezed,
    Object? mapUrl = freezed,
    Object? isCompleted = null,
  }) {
    return _then(_value.copyWith(
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      activity: null == activity
          ? _value.activity
          : activity // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      mapUrl: freezed == mapUrl
          ? _value.mapUrl
          : mapUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItineraryItemImplCopyWith<$Res>
    implements $ItineraryItemCopyWith<$Res> {
  factory _$$ItineraryItemImplCopyWith(
          _$ItineraryItemImpl value, $Res Function(_$ItineraryItemImpl) then) =
      __$$ItineraryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String time,
      String activity,
      String location,
      String? description,
      String? mapUrl,
      bool isCompleted});
}

/// @nodoc
class __$$ItineraryItemImplCopyWithImpl<$Res>
    extends _$ItineraryItemCopyWithImpl<$Res, _$ItineraryItemImpl>
    implements _$$ItineraryItemImplCopyWith<$Res> {
  __$$ItineraryItemImplCopyWithImpl(
      _$ItineraryItemImpl _value, $Res Function(_$ItineraryItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? activity = null,
    Object? location = null,
    Object? description = freezed,
    Object? mapUrl = freezed,
    Object? isCompleted = null,
  }) {
    return _then(_$ItineraryItemImpl(
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      activity: null == activity
          ? _value.activity
          : activity // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      mapUrl: freezed == mapUrl
          ? _value.mapUrl
          : mapUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItineraryItemImpl implements _ItineraryItem {
  const _$ItineraryItemImpl(
      {required this.time,
      required this.activity,
      required this.location,
      this.description,
      this.mapUrl,
      this.isCompleted = false});

  factory _$ItineraryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryItemImplFromJson(json);

  @override
  final String time;
  @override
  final String activity;
  @override
  final String location;
  @override
  final String? description;
  @override
  final String? mapUrl;
  @override
  @JsonKey()
  final bool isCompleted;

  @override
  String toString() {
    return 'ItineraryItem(time: $time, activity: $activity, location: $location, description: $description, mapUrl: $mapUrl, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryItemImpl &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.activity, activity) ||
                other.activity == activity) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.mapUrl, mapUrl) || other.mapUrl == mapUrl) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, time, activity, location, description, mapUrl, isCompleted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryItemImplCopyWith<_$ItineraryItemImpl> get copyWith =>
      __$$ItineraryItemImplCopyWithImpl<_$ItineraryItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryItemImplToJson(
      this,
    );
  }
}

abstract class _ItineraryItem implements ItineraryItem {
  const factory _ItineraryItem(
      {required final String time,
      required final String activity,
      required final String location,
      final String? description,
      final String? mapUrl,
      final bool isCompleted}) = _$ItineraryItemImpl;

  factory _ItineraryItem.fromJson(Map<String, dynamic> json) =
      _$ItineraryItemImpl.fromJson;

  @override
  String get time;
  @override
  String get activity;
  @override
  String get location;
  @override
  String? get description;
  @override
  String? get mapUrl;
  @override
  bool get isCompleted;
  @override
  @JsonKey(ignore: true)
  _$$ItineraryItemImplCopyWith<_$ItineraryItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

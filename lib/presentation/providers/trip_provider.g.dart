// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tripsListHash() => r'bc6b6425f9588768a13222c060bd42c65d681b92';

/// See also [tripsList].
@ProviderFor(tripsList)
final tripsListProvider = AutoDisposeFutureProvider<List<Trip>>.internal(
  tripsList,
  name: r'tripsListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tripsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TripsListRef = AutoDisposeFutureProviderRef<List<Trip>>;
String _$tripByIdHash() => r'7bdf7ff2814d28a49780e1d441653c8211c51a56';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [tripById].
@ProviderFor(tripById)
const tripByIdProvider = TripByIdFamily();

/// See also [tripById].
class TripByIdFamily extends Family<AsyncValue<Trip?>> {
  /// See also [tripById].
  const TripByIdFamily();

  /// See also [tripById].
  TripByIdProvider call(
    String tripId,
  ) {
    return TripByIdProvider(
      tripId,
    );
  }

  @override
  TripByIdProvider getProviderOverride(
    covariant TripByIdProvider provider,
  ) {
    return call(
      provider.tripId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'tripByIdProvider';
}

/// See also [tripById].
class TripByIdProvider extends AutoDisposeFutureProvider<Trip?> {
  /// See also [tripById].
  TripByIdProvider(
    String tripId,
  ) : this._internal(
          (ref) => tripById(
            ref as TripByIdRef,
            tripId,
          ),
          from: tripByIdProvider,
          name: r'tripByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tripByIdHash,
          dependencies: TripByIdFamily._dependencies,
          allTransitiveDependencies: TripByIdFamily._allTransitiveDependencies,
          tripId: tripId,
        );

  TripByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tripId,
  }) : super.internal();

  final String tripId;

  @override
  Override overrideWith(
    FutureOr<Trip?> Function(TripByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TripByIdProvider._internal(
        (ref) => create(ref as TripByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tripId: tripId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Trip?> createElement() {
    return _TripByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TripByIdProvider && other.tripId == tripId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tripId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TripByIdRef on AutoDisposeFutureProviderRef<Trip?> {
  /// The parameter `tripId` of this provider.
  String get tripId;
}

class _TripByIdProviderElement extends AutoDisposeFutureProviderElement<Trip?>
    with TripByIdRef {
  _TripByIdProviderElement(super.provider);

  @override
  String get tripId => (origin as TripByIdProvider).tripId;
}

String _$tripNotifierHash() => r'cf23b531823cdce2d5e1e75181713e530abdf04e';

/// See also [TripNotifier].
@ProviderFor(TripNotifier)
final tripNotifierProvider =
    AutoDisposeNotifierProvider<TripNotifier, AsyncValue<Trip?>>.internal(
  TripNotifier.new,
  name: r'tripNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tripNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TripNotifier = AutoDisposeNotifier<AsyncValue<Trip?>>;
String _$chatNotifierHash() => r'028076c2ccb112f73dde2a5fbdc62a21d04f6af7';

/// See also [ChatNotifier].
@ProviderFor(ChatNotifier)
final chatNotifierProvider =
    AutoDisposeNotifierProvider<ChatNotifier, List<ChatMessage>>.internal(
  ChatNotifier.new,
  name: r'chatNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatNotifier = AutoDisposeNotifier<List<ChatMessage>>;
String _$itineraryStreamNotifierHash() =>
    r'e3c7fbb8ea2b56470a5d2c6c6d4377fa4a63f03b';

/// See also [ItineraryStreamNotifier].
@ProviderFor(ItineraryStreamNotifier)
final itineraryStreamNotifierProvider = AutoDisposeNotifierProvider<
    ItineraryStreamNotifier, AsyncValue<String>>.internal(
  ItineraryStreamNotifier.new,
  name: r'itineraryStreamNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$itineraryStreamNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ItineraryStreamNotifier = AutoDisposeNotifier<AsyncValue<String>>;
String _$uiStateNotifierHash() => r'd1d09338f24e4882aa74b5e0aec8d809c8e9a359';

/// See also [UiStateNotifier].
@ProviderFor(UiStateNotifier)
final uiStateNotifierProvider =
    AutoDisposeNotifierProvider<UiStateNotifier, UiState>.internal(
  UiStateNotifier.new,
  name: r'uiStateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uiStateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UiStateNotifier = AutoDisposeNotifier<UiState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

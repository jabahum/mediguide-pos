// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_guideline_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$readGuidelineControllerHash() =>
    r'bce1a4a6ffaf7ebe36ba68a630643979831dbbcb';

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

abstract class _$ReadGuidelineController
    extends BuildlessAutoDisposeAsyncNotifier<ReadGuidelineState> {
  late final ReadGuidelineRequest request;

  FutureOr<ReadGuidelineState> build(ReadGuidelineRequest request);
}

/// See also [ReadGuidelineController].
@ProviderFor(ReadGuidelineController)
const readGuidelineControllerProvider = ReadGuidelineControllerFamily();

/// See also [ReadGuidelineController].
class ReadGuidelineControllerFamily
    extends Family<AsyncValue<ReadGuidelineState>> {
  /// See also [ReadGuidelineController].
  const ReadGuidelineControllerFamily();

  /// See also [ReadGuidelineController].
  ReadGuidelineControllerProvider call(ReadGuidelineRequest request) {
    return ReadGuidelineControllerProvider(request);
  }

  @override
  ReadGuidelineControllerProvider getProviderOverride(
    covariant ReadGuidelineControllerProvider provider,
  ) {
    return call(provider.request);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'readGuidelineControllerProvider';
}

/// See also [ReadGuidelineController].
class ReadGuidelineControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ReadGuidelineController,
          ReadGuidelineState
        > {
  /// See also [ReadGuidelineController].
  ReadGuidelineControllerProvider(ReadGuidelineRequest request)
    : this._internal(
        () => ReadGuidelineController()..request = request,
        from: readGuidelineControllerProvider,
        name: r'readGuidelineControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$readGuidelineControllerHash,
        dependencies: ReadGuidelineControllerFamily._dependencies,
        allTransitiveDependencies:
            ReadGuidelineControllerFamily._allTransitiveDependencies,
        request: request,
      );

  ReadGuidelineControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.request,
  }) : super.internal();

  final ReadGuidelineRequest request;

  @override
  FutureOr<ReadGuidelineState> runNotifierBuild(
    covariant ReadGuidelineController notifier,
  ) {
    return notifier.build(request);
  }

  @override
  Override overrideWith(ReadGuidelineController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ReadGuidelineControllerProvider._internal(
        () => create()..request = request,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        request: request,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ReadGuidelineController,
    ReadGuidelineState
  >
  createElement() {
    return _ReadGuidelineControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReadGuidelineControllerProvider && other.request == request;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, request.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReadGuidelineControllerRef
    on AutoDisposeAsyncNotifierProviderRef<ReadGuidelineState> {
  /// The parameter `request` of this provider.
  ReadGuidelineRequest get request;
}

class _ReadGuidelineControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ReadGuidelineController,
          ReadGuidelineState
        >
    with ReadGuidelineControllerRef {
  _ReadGuidelineControllerProviderElement(super.provider);

  @override
  ReadGuidelineRequest get request =>
      (origin as ReadGuidelineControllerProvider).request;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_infrastructure_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$healthInfrastructureControllerHash() =>
    r'e5060a113c432e683f7d3da3938171ab01715c80';

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

abstract class _$HealthInfrastructureController
    extends BuildlessAutoDisposeNotifier<HealthInfrastructureState> {
  late final Object? arguments;

  HealthInfrastructureState build(Object? arguments);
}

/// See also [HealthInfrastructureController].
@ProviderFor(HealthInfrastructureController)
const healthInfrastructureControllerProvider =
    HealthInfrastructureControllerFamily();

/// See also [HealthInfrastructureController].
class HealthInfrastructureControllerFamily
    extends Family<HealthInfrastructureState> {
  /// See also [HealthInfrastructureController].
  const HealthInfrastructureControllerFamily();

  /// See also [HealthInfrastructureController].
  HealthInfrastructureControllerProvider call(Object? arguments) {
    return HealthInfrastructureControllerProvider(arguments);
  }

  @override
  HealthInfrastructureControllerProvider getProviderOverride(
    covariant HealthInfrastructureControllerProvider provider,
  ) {
    return call(provider.arguments);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'healthInfrastructureControllerProvider';
}

/// See also [HealthInfrastructureController].
class HealthInfrastructureControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<
          HealthInfrastructureController,
          HealthInfrastructureState
        > {
  /// See also [HealthInfrastructureController].
  HealthInfrastructureControllerProvider(Object? arguments)
    : this._internal(
        () => HealthInfrastructureController()..arguments = arguments,
        from: healthInfrastructureControllerProvider,
        name: r'healthInfrastructureControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$healthInfrastructureControllerHash,
        dependencies: HealthInfrastructureControllerFamily._dependencies,
        allTransitiveDependencies:
            HealthInfrastructureControllerFamily._allTransitiveDependencies,
        arguments: arguments,
      );

  HealthInfrastructureControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.arguments,
  }) : super.internal();

  final Object? arguments;

  @override
  HealthInfrastructureState runNotifierBuild(
    covariant HealthInfrastructureController notifier,
  ) {
    return notifier.build(arguments);
  }

  @override
  Override overrideWith(HealthInfrastructureController Function() create) {
    return ProviderOverride(
      origin: this,
      override: HealthInfrastructureControllerProvider._internal(
        () => create()..arguments = arguments,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        arguments: arguments,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    HealthInfrastructureController,
    HealthInfrastructureState
  >
  createElement() {
    return _HealthInfrastructureControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HealthInfrastructureControllerProvider &&
        other.arguments == arguments;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, arguments.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HealthInfrastructureControllerRef
    on AutoDisposeNotifierProviderRef<HealthInfrastructureState> {
  /// The parameter `arguments` of this provider.
  Object? get arguments;
}

class _HealthInfrastructureControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          HealthInfrastructureController,
          HealthInfrastructureState
        >
    with HealthInfrastructureControllerRef {
  _HealthInfrastructureControllerProviderElement(super.provider);

  @override
  Object? get arguments =>
      (origin as HealthInfrastructureControllerProvider).arguments;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

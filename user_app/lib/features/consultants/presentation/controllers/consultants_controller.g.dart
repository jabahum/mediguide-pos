// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consultants_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$consultantsControllerHash() =>
    r'9edd43125b44bd0703d56bc0dbad9c95dac9dc88';

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

abstract class _$ConsultantsController
    extends BuildlessAutoDisposeNotifier<ConsultantsState> {
  late final Object? arguments;

  ConsultantsState build(Object? arguments);
}

/// See also [ConsultantsController].
@ProviderFor(ConsultantsController)
const consultantsControllerProvider = ConsultantsControllerFamily();

/// See also [ConsultantsController].
class ConsultantsControllerFamily extends Family<ConsultantsState> {
  /// See also [ConsultantsController].
  const ConsultantsControllerFamily();

  /// See also [ConsultantsController].
  ConsultantsControllerProvider call(Object? arguments) {
    return ConsultantsControllerProvider(arguments);
  }

  @override
  ConsultantsControllerProvider getProviderOverride(
    covariant ConsultantsControllerProvider provider,
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
  String? get name => r'consultantsControllerProvider';
}

/// See also [ConsultantsController].
class ConsultantsControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<
          ConsultantsController,
          ConsultantsState
        > {
  /// See also [ConsultantsController].
  ConsultantsControllerProvider(Object? arguments)
    : this._internal(
        () => ConsultantsController()..arguments = arguments,
        from: consultantsControllerProvider,
        name: r'consultantsControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$consultantsControllerHash,
        dependencies: ConsultantsControllerFamily._dependencies,
        allTransitiveDependencies:
            ConsultantsControllerFamily._allTransitiveDependencies,
        arguments: arguments,
      );

  ConsultantsControllerProvider._internal(
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
  ConsultantsState runNotifierBuild(covariant ConsultantsController notifier) {
    return notifier.build(arguments);
  }

  @override
  Override overrideWith(ConsultantsController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ConsultantsControllerProvider._internal(
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
  AutoDisposeNotifierProviderElement<ConsultantsController, ConsultantsState>
  createElement() {
    return _ConsultantsControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConsultantsControllerProvider &&
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
mixin ConsultantsControllerRef
    on AutoDisposeNotifierProviderRef<ConsultantsState> {
  /// The parameter `arguments` of this provider.
  Object? get arguments;
}

class _ConsultantsControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          ConsultantsController,
          ConsultantsState
        >
    with ConsultantsControllerRef {
  _ConsultantsControllerProviderElement(super.provider);

  @override
  Object? get arguments => (origin as ConsultantsControllerProvider).arguments;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

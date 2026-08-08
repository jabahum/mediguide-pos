// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guidelines_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$guidelinesControllerHash() =>
    r'c45990c2c9fc1002552cdb574c11e6f9a6a7ef91';

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

abstract class _$GuidelinesController
    extends BuildlessAutoDisposeNotifier<GuidelinesState> {
  late final Object? arguments;

  GuidelinesState build(Object? arguments);
}

/// See also [GuidelinesController].
@ProviderFor(GuidelinesController)
const guidelinesControllerProvider = GuidelinesControllerFamily();

/// See also [GuidelinesController].
class GuidelinesControllerFamily extends Family<GuidelinesState> {
  /// See also [GuidelinesController].
  const GuidelinesControllerFamily();

  /// See also [GuidelinesController].
  GuidelinesControllerProvider call(Object? arguments) {
    return GuidelinesControllerProvider(arguments);
  }

  @override
  GuidelinesControllerProvider getProviderOverride(
    covariant GuidelinesControllerProvider provider,
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
  String? get name => r'guidelinesControllerProvider';
}

/// See also [GuidelinesController].
class GuidelinesControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<GuidelinesController, GuidelinesState> {
  /// See also [GuidelinesController].
  GuidelinesControllerProvider(Object? arguments)
    : this._internal(
        () => GuidelinesController()..arguments = arguments,
        from: guidelinesControllerProvider,
        name: r'guidelinesControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$guidelinesControllerHash,
        dependencies: GuidelinesControllerFamily._dependencies,
        allTransitiveDependencies:
            GuidelinesControllerFamily._allTransitiveDependencies,
        arguments: arguments,
      );

  GuidelinesControllerProvider._internal(
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
  GuidelinesState runNotifierBuild(covariant GuidelinesController notifier) {
    return notifier.build(arguments);
  }

  @override
  Override overrideWith(GuidelinesController Function() create) {
    return ProviderOverride(
      origin: this,
      override: GuidelinesControllerProvider._internal(
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
  AutoDisposeNotifierProviderElement<GuidelinesController, GuidelinesState>
  createElement() {
    return _GuidelinesControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GuidelinesControllerProvider &&
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
mixin GuidelinesControllerRef
    on AutoDisposeNotifierProviderRef<GuidelinesState> {
  /// The parameter `arguments` of this provider.
  Object? get arguments;
}

class _GuidelinesControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          GuidelinesController,
          GuidelinesState
        >
    with GuidelinesControllerRef {
  _GuidelinesControllerProviderElement(super.provider);

  @override
  Object? get arguments => (origin as GuidelinesControllerProvider).arguments;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

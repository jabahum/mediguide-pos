// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'use_calculator_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$calculatorContentLoaderHash() =>
    r'14e3534c2a2bacef463112b784658ba74882df09';

/// ======================================================
/// CONTENT LOADER PROVIDER
/// ======================================================
///
/// Copied from [calculatorContentLoader].
@ProviderFor(calculatorContentLoader)
final calculatorContentLoaderProvider =
    AutoDisposeProvider<CalculatorContentLoader>.internal(
      calculatorContentLoader,
      name: r'calculatorContentLoaderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$calculatorContentLoaderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CalculatorContentLoaderRef =
    AutoDisposeProviderRef<CalculatorContentLoader>;
String _$useCalculatorControllerHash() =>
    r'3a5f328044fbda690fb46f260f9663a940e91288';

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

abstract class _$UseCalculatorController
    extends BuildlessAutoDisposeAsyncNotifier<UseCalculatorState> {
  late final UseCalculatorRequest request;

  FutureOr<UseCalculatorState> build(UseCalculatorRequest request);
}

/// ======================================================
/// CONTROLLER
/// ======================================================
///
/// Copied from [UseCalculatorController].
@ProviderFor(UseCalculatorController)
const useCalculatorControllerProvider = UseCalculatorControllerFamily();

/// ======================================================
/// CONTROLLER
/// ======================================================
///
/// Copied from [UseCalculatorController].
class UseCalculatorControllerFamily
    extends Family<AsyncValue<UseCalculatorState>> {
  /// ======================================================
  /// CONTROLLER
  /// ======================================================
  ///
  /// Copied from [UseCalculatorController].
  const UseCalculatorControllerFamily();

  /// ======================================================
  /// CONTROLLER
  /// ======================================================
  ///
  /// Copied from [UseCalculatorController].
  UseCalculatorControllerProvider call(UseCalculatorRequest request) {
    return UseCalculatorControllerProvider(request);
  }

  @override
  UseCalculatorControllerProvider getProviderOverride(
    covariant UseCalculatorControllerProvider provider,
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
  String? get name => r'useCalculatorControllerProvider';
}

/// ======================================================
/// CONTROLLER
/// ======================================================
///
/// Copied from [UseCalculatorController].
class UseCalculatorControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          UseCalculatorController,
          UseCalculatorState
        > {
  /// ======================================================
  /// CONTROLLER
  /// ======================================================
  ///
  /// Copied from [UseCalculatorController].
  UseCalculatorControllerProvider(UseCalculatorRequest request)
    : this._internal(
        () => UseCalculatorController()..request = request,
        from: useCalculatorControllerProvider,
        name: r'useCalculatorControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$useCalculatorControllerHash,
        dependencies: UseCalculatorControllerFamily._dependencies,
        allTransitiveDependencies:
            UseCalculatorControllerFamily._allTransitiveDependencies,
        request: request,
      );

  UseCalculatorControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.request,
  }) : super.internal();

  final UseCalculatorRequest request;

  @override
  FutureOr<UseCalculatorState> runNotifierBuild(
    covariant UseCalculatorController notifier,
  ) {
    return notifier.build(request);
  }

  @override
  Override overrideWith(UseCalculatorController Function() create) {
    return ProviderOverride(
      origin: this,
      override: UseCalculatorControllerProvider._internal(
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
    UseCalculatorController,
    UseCalculatorState
  >
  createElement() {
    return _UseCalculatorControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UseCalculatorControllerProvider && other.request == request;
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
mixin UseCalculatorControllerRef
    on AutoDisposeAsyncNotifierProviderRef<UseCalculatorState> {
  /// The parameter `request` of this provider.
  UseCalculatorRequest get request;
}

class _UseCalculatorControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          UseCalculatorController,
          UseCalculatorState
        >
    with UseCalculatorControllerRef {
  _UseCalculatorControllerProviderElement(super.provider);

  @override
  UseCalculatorRequest get request =>
      (origin as UseCalculatorControllerProvider).request;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

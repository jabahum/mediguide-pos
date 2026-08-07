// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tools_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$toolsControllerHash() => r'2c7c09d9d8ac9944e2065a5650ee55c8d0e675ad';

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

abstract class _$ToolsController
    extends BuildlessAutoDisposeNotifier<ToolsState> {
  late final Object? arguments;

  ToolsState build(Object? arguments);
}

/// ======================================================
/// CONTROLLER
/// ======================================================
///
/// Copied from [ToolsController].
@ProviderFor(ToolsController)
const toolsControllerProvider = ToolsControllerFamily();

/// ======================================================
/// CONTROLLER
/// ======================================================
///
/// Copied from [ToolsController].
class ToolsControllerFamily extends Family<ToolsState> {
  /// ======================================================
  /// CONTROLLER
  /// ======================================================
  ///
  /// Copied from [ToolsController].
  const ToolsControllerFamily();

  /// ======================================================
  /// CONTROLLER
  /// ======================================================
  ///
  /// Copied from [ToolsController].
  ToolsControllerProvider call(Object? arguments) {
    return ToolsControllerProvider(arguments);
  }

  @override
  ToolsControllerProvider getProviderOverride(
    covariant ToolsControllerProvider provider,
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
  String? get name => r'toolsControllerProvider';
}

/// ======================================================
/// CONTROLLER
/// ======================================================
///
/// Copied from [ToolsController].
class ToolsControllerProvider
    extends AutoDisposeNotifierProviderImpl<ToolsController, ToolsState> {
  /// ======================================================
  /// CONTROLLER
  /// ======================================================
  ///
  /// Copied from [ToolsController].
  ToolsControllerProvider(Object? arguments)
    : this._internal(
        () => ToolsController()..arguments = arguments,
        from: toolsControllerProvider,
        name: r'toolsControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$toolsControllerHash,
        dependencies: ToolsControllerFamily._dependencies,
        allTransitiveDependencies:
            ToolsControllerFamily._allTransitiveDependencies,
        arguments: arguments,
      );

  ToolsControllerProvider._internal(
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
  ToolsState runNotifierBuild(covariant ToolsController notifier) {
    return notifier.build(arguments);
  }

  @override
  Override overrideWith(ToolsController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ToolsControllerProvider._internal(
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
  AutoDisposeNotifierProviderElement<ToolsController, ToolsState>
  createElement() {
    return _ToolsControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ToolsControllerProvider && other.arguments == arguments;
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
mixin ToolsControllerRef on AutoDisposeNotifierProviderRef<ToolsState> {
  /// The parameter `arguments` of this provider.
  Object? get arguments;
}

class _ToolsControllerProviderElement
    extends AutoDisposeNotifierProviderElement<ToolsController, ToolsState>
    with ToolsControllerRef {
  _ToolsControllerProviderElement(super.provider);

  @override
  Object? get arguments => (origin as ToolsControllerProvider).arguments;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

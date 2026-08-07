// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tree_selector_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$treeSelectorControllerHash() =>
    r'79623eb7a2f4df3182a25d9b0e089b03be90da93';

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

abstract class _$TreeSelectorController
    extends BuildlessAutoDisposeNotifier<TreeSelectorState> {
  late final TreeSelectorConfig config;

  TreeSelectorState build(TreeSelectorConfig config);
}

/// See also [TreeSelectorController].
@ProviderFor(TreeSelectorController)
const treeSelectorControllerProvider = TreeSelectorControllerFamily();

/// See also [TreeSelectorController].
class TreeSelectorControllerFamily extends Family<TreeSelectorState> {
  /// See also [TreeSelectorController].
  const TreeSelectorControllerFamily();

  /// See also [TreeSelectorController].
  TreeSelectorControllerProvider call(TreeSelectorConfig config) {
    return TreeSelectorControllerProvider(config);
  }

  @override
  TreeSelectorControllerProvider getProviderOverride(
    covariant TreeSelectorControllerProvider provider,
  ) {
    return call(provider.config);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'treeSelectorControllerProvider';
}

/// See also [TreeSelectorController].
class TreeSelectorControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<
          TreeSelectorController,
          TreeSelectorState
        > {
  /// See also [TreeSelectorController].
  TreeSelectorControllerProvider(TreeSelectorConfig config)
    : this._internal(
        () => TreeSelectorController()..config = config,
        from: treeSelectorControllerProvider,
        name: r'treeSelectorControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$treeSelectorControllerHash,
        dependencies: TreeSelectorControllerFamily._dependencies,
        allTransitiveDependencies:
            TreeSelectorControllerFamily._allTransitiveDependencies,
        config: config,
      );

  TreeSelectorControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.config,
  }) : super.internal();

  final TreeSelectorConfig config;

  @override
  TreeSelectorState runNotifierBuild(
    covariant TreeSelectorController notifier,
  ) {
    return notifier.build(config);
  }

  @override
  Override overrideWith(TreeSelectorController Function() create) {
    return ProviderOverride(
      origin: this,
      override: TreeSelectorControllerProvider._internal(
        () => create()..config = config,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        config: config,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<TreeSelectorController, TreeSelectorState>
  createElement() {
    return _TreeSelectorControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TreeSelectorControllerProvider && other.config == config;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, config.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TreeSelectorControllerRef
    on AutoDisposeNotifierProviderRef<TreeSelectorState> {
  /// The parameter `config` of this provider.
  TreeSelectorConfig get config;
}

class _TreeSelectorControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          TreeSelectorController,
          TreeSelectorState
        >
    with TreeSelectorControllerRef {
  _TreeSelectorControllerProviderElement(super.provider);

  @override
  TreeSelectorConfig get config =>
      (origin as TreeSelectorControllerProvider).config;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

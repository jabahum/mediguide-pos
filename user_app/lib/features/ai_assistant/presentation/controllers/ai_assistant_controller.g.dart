// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_assistant_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiAssistantControllerHash() =>
    r'14210aac9b1c4dd33a84edf96058913ba5e49b73';

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

abstract class _$AiAssistantController
    extends BuildlessAutoDisposeNotifier<AiAssistantState> {
  late final AiContext? initialContext;

  AiAssistantState build(AiContext? initialContext);
}

/// See also [AiAssistantController].
@ProviderFor(AiAssistantController)
const aiAssistantControllerProvider = AiAssistantControllerFamily();

/// See also [AiAssistantController].
class AiAssistantControllerFamily extends Family<AiAssistantState> {
  /// See also [AiAssistantController].
  const AiAssistantControllerFamily();

  /// See also [AiAssistantController].
  AiAssistantControllerProvider call(AiContext? initialContext) {
    return AiAssistantControllerProvider(initialContext);
  }

  @override
  AiAssistantControllerProvider getProviderOverride(
    covariant AiAssistantControllerProvider provider,
  ) {
    return call(provider.initialContext);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'aiAssistantControllerProvider';
}

/// See also [AiAssistantController].
class AiAssistantControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<
          AiAssistantController,
          AiAssistantState
        > {
  /// See also [AiAssistantController].
  AiAssistantControllerProvider(AiContext? initialContext)
    : this._internal(
        () => AiAssistantController()..initialContext = initialContext,
        from: aiAssistantControllerProvider,
        name: r'aiAssistantControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$aiAssistantControllerHash,
        dependencies: AiAssistantControllerFamily._dependencies,
        allTransitiveDependencies:
            AiAssistantControllerFamily._allTransitiveDependencies,
        initialContext: initialContext,
      );

  AiAssistantControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.initialContext,
  }) : super.internal();

  final AiContext? initialContext;

  @override
  AiAssistantState runNotifierBuild(covariant AiAssistantController notifier) {
    return notifier.build(initialContext);
  }

  @override
  Override overrideWith(AiAssistantController Function() create) {
    return ProviderOverride(
      origin: this,
      override: AiAssistantControllerProvider._internal(
        () => create()..initialContext = initialContext,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        initialContext: initialContext,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<AiAssistantController, AiAssistantState>
  createElement() {
    return _AiAssistantControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AiAssistantControllerProvider &&
        other.initialContext == initialContext;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, initialContext.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AiAssistantControllerRef
    on AutoDisposeNotifierProviderRef<AiAssistantState> {
  /// The parameter `initialContext` of this provider.
  AiContext? get initialContext;
}

class _AiAssistantControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          AiAssistantController,
          AiAssistantState
        >
    with AiAssistantControllerRef {
  _AiAssistantControllerProviderElement(super.provider);

  @override
  AiContext? get initialContext =>
      (origin as AiAssistantControllerProvider).initialContext;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

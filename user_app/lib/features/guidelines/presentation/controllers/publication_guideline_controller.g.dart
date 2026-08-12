// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_guideline_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicationGuidelineHash() =>
    r'7c3f2ad52681f3a39cbcd2193c655f5de03f1000';

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

/// See also [publicationGuideline].
@ProviderFor(publicationGuideline)
const publicationGuidelineProvider = PublicationGuidelineFamily();

/// See also [publicationGuideline].
class PublicationGuidelineFamily
    extends Family<AsyncValue<GuidelinePublicationContent>> {
  /// See also [publicationGuideline].
  const PublicationGuidelineFamily();

  /// See also [publicationGuideline].
  PublicationGuidelineProvider call(String guidelineId) {
    return PublicationGuidelineProvider(guidelineId);
  }

  @override
  PublicationGuidelineProvider getProviderOverride(
    covariant PublicationGuidelineProvider provider,
  ) {
    return call(provider.guidelineId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publicationGuidelineProvider';
}

/// See also [publicationGuideline].
class PublicationGuidelineProvider
    extends AutoDisposeFutureProvider<GuidelinePublicationContent> {
  /// See also [publicationGuideline].
  PublicationGuidelineProvider(String guidelineId)
    : this._internal(
        (ref) =>
            publicationGuideline(ref as PublicationGuidelineRef, guidelineId),
        from: publicationGuidelineProvider,
        name: r'publicationGuidelineProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicationGuidelineHash,
        dependencies: PublicationGuidelineFamily._dependencies,
        allTransitiveDependencies:
            PublicationGuidelineFamily._allTransitiveDependencies,
        guidelineId: guidelineId,
      );

  PublicationGuidelineProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.guidelineId,
  }) : super.internal();

  final String guidelineId;

  @override
  Override overrideWith(
    FutureOr<GuidelinePublicationContent> Function(
      PublicationGuidelineRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicationGuidelineProvider._internal(
        (ref) => create(ref as PublicationGuidelineRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        guidelineId: guidelineId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GuidelinePublicationContent>
  createElement() {
    return _PublicationGuidelineProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicationGuidelineProvider &&
        other.guidelineId == guidelineId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, guidelineId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicationGuidelineRef
    on AutoDisposeFutureProviderRef<GuidelinePublicationContent> {
  /// The parameter `guidelineId` of this provider.
  String get guidelineId;
}

class _PublicationGuidelineProviderElement
    extends AutoDisposeFutureProviderElement<GuidelinePublicationContent>
    with PublicationGuidelineRef {
  _PublicationGuidelineProviderElement(super.provider);

  @override
  String get guidelineId =>
      (origin as PublicationGuidelineProvider).guidelineId;
}

String _$guidelineOriginalDocumentHash() =>
    r'5292612f7e926123ebc32cfdf2a2db36cf6a8d39';

/// See also [guidelineOriginalDocument].
@ProviderFor(guidelineOriginalDocument)
const guidelineOriginalDocumentProvider = GuidelineOriginalDocumentFamily();

/// See also [guidelineOriginalDocument].
class GuidelineOriginalDocumentFamily
    extends Family<AsyncValue<GuidelineAsset?>> {
  /// See also [guidelineOriginalDocument].
  const GuidelineOriginalDocumentFamily();

  /// See also [guidelineOriginalDocument].
  GuidelineOriginalDocumentProvider call(String guidelineId) {
    return GuidelineOriginalDocumentProvider(guidelineId);
  }

  @override
  GuidelineOriginalDocumentProvider getProviderOverride(
    covariant GuidelineOriginalDocumentProvider provider,
  ) {
    return call(provider.guidelineId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'guidelineOriginalDocumentProvider';
}

/// See also [guidelineOriginalDocument].
class GuidelineOriginalDocumentProvider
    extends AutoDisposeFutureProvider<GuidelineAsset?> {
  /// See also [guidelineOriginalDocument].
  GuidelineOriginalDocumentProvider(String guidelineId)
    : this._internal(
        (ref) => guidelineOriginalDocument(
          ref as GuidelineOriginalDocumentRef,
          guidelineId,
        ),
        from: guidelineOriginalDocumentProvider,
        name: r'guidelineOriginalDocumentProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$guidelineOriginalDocumentHash,
        dependencies: GuidelineOriginalDocumentFamily._dependencies,
        allTransitiveDependencies:
            GuidelineOriginalDocumentFamily._allTransitiveDependencies,
        guidelineId: guidelineId,
      );

  GuidelineOriginalDocumentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.guidelineId,
  }) : super.internal();

  final String guidelineId;

  @override
  Override overrideWith(
    FutureOr<GuidelineAsset?> Function(GuidelineOriginalDocumentRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GuidelineOriginalDocumentProvider._internal(
        (ref) => create(ref as GuidelineOriginalDocumentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        guidelineId: guidelineId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GuidelineAsset?> createElement() {
    return _GuidelineOriginalDocumentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GuidelineOriginalDocumentProvider &&
        other.guidelineId == guidelineId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, guidelineId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GuidelineOriginalDocumentRef
    on AutoDisposeFutureProviderRef<GuidelineAsset?> {
  /// The parameter `guidelineId` of this provider.
  String get guidelineId;
}

class _GuidelineOriginalDocumentProviderElement
    extends AutoDisposeFutureProviderElement<GuidelineAsset?>
    with GuidelineOriginalDocumentRef {
  _GuidelineOriginalDocumentProviderElement(super.provider);

  @override
  String get guidelineId =>
      (origin as GuidelineOriginalDocumentProvider).guidelineId;
}

String _$guidelineOfflinePackageHash() =>
    r'34b9c0a950c3c54c7bdcfedb1a88a8aa99aeea03';

/// See also [guidelineOfflinePackage].
@ProviderFor(guidelineOfflinePackage)
const guidelineOfflinePackageProvider = GuidelineOfflinePackageFamily();

/// See also [guidelineOfflinePackage].
class GuidelineOfflinePackageFamily
    extends Family<AsyncValue<GuidelineAsset?>> {
  /// See also [guidelineOfflinePackage].
  const GuidelineOfflinePackageFamily();

  /// See also [guidelineOfflinePackage].
  GuidelineOfflinePackageProvider call(String guidelineId) {
    return GuidelineOfflinePackageProvider(guidelineId);
  }

  @override
  GuidelineOfflinePackageProvider getProviderOverride(
    covariant GuidelineOfflinePackageProvider provider,
  ) {
    return call(provider.guidelineId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'guidelineOfflinePackageProvider';
}

/// See also [guidelineOfflinePackage].
class GuidelineOfflinePackageProvider
    extends AutoDisposeFutureProvider<GuidelineAsset?> {
  /// See also [guidelineOfflinePackage].
  GuidelineOfflinePackageProvider(String guidelineId)
    : this._internal(
        (ref) => guidelineOfflinePackage(
          ref as GuidelineOfflinePackageRef,
          guidelineId,
        ),
        from: guidelineOfflinePackageProvider,
        name: r'guidelineOfflinePackageProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$guidelineOfflinePackageHash,
        dependencies: GuidelineOfflinePackageFamily._dependencies,
        allTransitiveDependencies:
            GuidelineOfflinePackageFamily._allTransitiveDependencies,
        guidelineId: guidelineId,
      );

  GuidelineOfflinePackageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.guidelineId,
  }) : super.internal();

  final String guidelineId;

  @override
  Override overrideWith(
    FutureOr<GuidelineAsset?> Function(GuidelineOfflinePackageRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GuidelineOfflinePackageProvider._internal(
        (ref) => create(ref as GuidelineOfflinePackageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        guidelineId: guidelineId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GuidelineAsset?> createElement() {
    return _GuidelineOfflinePackageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GuidelineOfflinePackageProvider &&
        other.guidelineId == guidelineId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, guidelineId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GuidelineOfflinePackageRef
    on AutoDisposeFutureProviderRef<GuidelineAsset?> {
  /// The parameter `guidelineId` of this provider.
  String get guidelineId;
}

class _GuidelineOfflinePackageProviderElement
    extends AutoDisposeFutureProviderElement<GuidelineAsset?>
    with GuidelineOfflinePackageRef {
  _GuidelineOfflinePackageProviderElement(super.provider);

  @override
  String get guidelineId =>
      (origin as GuidelineOfflinePackageProvider).guidelineId;
}

String _$publicationReadingProgressHash() =>
    r'c6a1b6e4489beaf32d23daac7485e387fe3e8529';

/// See also [publicationReadingProgress].
@ProviderFor(publicationReadingProgress)
const publicationReadingProgressProvider = PublicationReadingProgressFamily();

/// See also [publicationReadingProgress].
class PublicationReadingProgressFamily
    extends Family<AsyncValue<ReadingProgress?>> {
  /// See also [publicationReadingProgress].
  const PublicationReadingProgressFamily();

  /// See also [publicationReadingProgress].
  PublicationReadingProgressProvider call(String guidelineId) {
    return PublicationReadingProgressProvider(guidelineId);
  }

  @override
  PublicationReadingProgressProvider getProviderOverride(
    covariant PublicationReadingProgressProvider provider,
  ) {
    return call(provider.guidelineId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publicationReadingProgressProvider';
}

/// See also [publicationReadingProgress].
class PublicationReadingProgressProvider
    extends AutoDisposeFutureProvider<ReadingProgress?> {
  /// See also [publicationReadingProgress].
  PublicationReadingProgressProvider(String guidelineId)
    : this._internal(
        (ref) => publicationReadingProgress(
          ref as PublicationReadingProgressRef,
          guidelineId,
        ),
        from: publicationReadingProgressProvider,
        name: r'publicationReadingProgressProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicationReadingProgressHash,
        dependencies: PublicationReadingProgressFamily._dependencies,
        allTransitiveDependencies:
            PublicationReadingProgressFamily._allTransitiveDependencies,
        guidelineId: guidelineId,
      );

  PublicationReadingProgressProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.guidelineId,
  }) : super.internal();

  final String guidelineId;

  @override
  Override overrideWith(
    FutureOr<ReadingProgress?> Function(PublicationReadingProgressRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicationReadingProgressProvider._internal(
        (ref) => create(ref as PublicationReadingProgressRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        guidelineId: guidelineId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ReadingProgress?> createElement() {
    return _PublicationReadingProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicationReadingProgressProvider &&
        other.guidelineId == guidelineId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, guidelineId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicationReadingProgressRef
    on AutoDisposeFutureProviderRef<ReadingProgress?> {
  /// The parameter `guidelineId` of this provider.
  String get guidelineId;
}

class _PublicationReadingProgressProviderElement
    extends AutoDisposeFutureProviderElement<ReadingProgress?>
    with PublicationReadingProgressRef {
  _PublicationReadingProgressProviderElement(super.provider);

  @override
  String get guidelineId =>
      (origin as PublicationReadingProgressProvider).guidelineId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

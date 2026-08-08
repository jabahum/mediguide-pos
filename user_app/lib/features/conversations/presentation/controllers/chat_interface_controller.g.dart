// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_interface_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatInterfaceControllerHash() =>
    r'523bdd2952365f7291e7d31aa1e2304b3952919d';

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

abstract class _$ChatInterfaceController
    extends BuildlessAutoDisposeNotifier<ChatInterfaceState> {
  late final User otherUser;

  ChatInterfaceState build(User otherUser);
}

/// See also [ChatInterfaceController].
@ProviderFor(ChatInterfaceController)
const chatInterfaceControllerProvider = ChatInterfaceControllerFamily();

/// See also [ChatInterfaceController].
class ChatInterfaceControllerFamily extends Family<ChatInterfaceState> {
  /// See also [ChatInterfaceController].
  const ChatInterfaceControllerFamily();

  /// See also [ChatInterfaceController].
  ChatInterfaceControllerProvider call(User otherUser) {
    return ChatInterfaceControllerProvider(otherUser);
  }

  @override
  ChatInterfaceControllerProvider getProviderOverride(
    covariant ChatInterfaceControllerProvider provider,
  ) {
    return call(provider.otherUser);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatInterfaceControllerProvider';
}

/// See also [ChatInterfaceController].
class ChatInterfaceControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<
          ChatInterfaceController,
          ChatInterfaceState
        > {
  /// See also [ChatInterfaceController].
  ChatInterfaceControllerProvider(User otherUser)
    : this._internal(
        () => ChatInterfaceController()..otherUser = otherUser,
        from: chatInterfaceControllerProvider,
        name: r'chatInterfaceControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatInterfaceControllerHash,
        dependencies: ChatInterfaceControllerFamily._dependencies,
        allTransitiveDependencies:
            ChatInterfaceControllerFamily._allTransitiveDependencies,
        otherUser: otherUser,
      );

  ChatInterfaceControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherUser,
  }) : super.internal();

  final User otherUser;

  @override
  ChatInterfaceState runNotifierBuild(
    covariant ChatInterfaceController notifier,
  ) {
    return notifier.build(otherUser);
  }

  @override
  Override overrideWith(ChatInterfaceController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatInterfaceControllerProvider._internal(
        () => create()..otherUser = otherUser,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherUser: otherUser,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    ChatInterfaceController,
    ChatInterfaceState
  >
  createElement() {
    return _ChatInterfaceControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatInterfaceControllerProvider &&
        other.otherUser == otherUser;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherUser.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatInterfaceControllerRef
    on AutoDisposeNotifierProviderRef<ChatInterfaceState> {
  /// The parameter `otherUser` of this provider.
  User get otherUser;
}

class _ChatInterfaceControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          ChatInterfaceController,
          ChatInterfaceState
        >
    with ChatInterfaceControllerRef {
  _ChatInterfaceControllerProviderElement(super.provider);

  @override
  User get otherUser => (origin as ChatInterfaceControllerProvider).otherUser;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

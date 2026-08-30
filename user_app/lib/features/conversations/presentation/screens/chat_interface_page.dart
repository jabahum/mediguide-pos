import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/conversations/data/models/message.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_interface_controller.dart';
import 'package:user_app/features/conversations/presentation/controllers/chat_interface_state.dart';

import 'package:user_app/shared/widgets/user_avatar.dart';

part '../widgets/chat_interface_page_chat_app_bar_title.dart';
part '../widgets/chat_interface_page_date_separator.dart';
part '../widgets/chat_interface_page_message_bubble.dart';
part '../widgets/chat_interface_page_reply_preview.dart';
part '../widgets/chat_interface_page_message_status_icon.dart';
part '../widgets/chat_interface_page_message_input_bar.dart';
part '../widgets/chat_interface_page_conversation_error_banner.dart';

class ChatInterfacePage extends ConsumerStatefulWidget {
  const ChatInterfacePage({super.key, this.otherUser});

  final User? otherUser;

  @override
  ConsumerState<ChatInterfacePage> createState() => _ChatInterfacePageState();
}

class _ChatInterfacePageState extends ConsumerState<ChatInterfacePage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _canSend = false;

  @override
  void initState() {
    super.initState();

    _textController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_handleTextChanged)
      ..dispose();

    _inputFocusNode.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _handleTextChanged() {
    final next = _textController.text.trim().isNotEmpty;

    if (next == _canSend) {
      return;
    }

    setState(() {
      _canSend = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.otherUser;

    if (otherUser == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState.noData(
          title: 'Conversation unavailable',
          description: 'The person for this conversation could not be found.',
        ),
      );
    }

    final provider = chatInterfaceControllerProvider(otherUser);

    final state = ref.watch(provider);

    final controller = ref.read(provider.notifier);

    ref.listen<int>(provider.select((value) => value.messages.length), (
      previous,
      next,
    ) {
      if (previous != next) {
        _scrollToBottom();
      }
    });

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        titleSpacing: AppSpacing.sm,
        title: _ChatAppBarTitle(otherUser: otherUser),
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // =================================================================
            // CONTENT
            // =================================================================
            Expanded(
              child: _buildConversationBody(
                context: context,
                state: state,
                controller: controller,
              ),
            ),

            // =================================================================
            // NON-BLOCKING ERROR
            // =================================================================
            if (state.errorMessage != null && state.messages.isNotEmpty)
              _ConversationErrorBanner(
                message: state.errorMessage!,
                onRetry: () {
                  controller.loadMessages();
                },
              ),

            // =================================================================
            // INPUT
            // =================================================================
            _MessageInputBar(
              controller: _textController,
              focusNode: _inputFocusNode,
              canSend: _canSend && !state.isLoading,
              isSending: state.isLoading,
              onSend: () {
                _sendMessage(controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationBody({
    required BuildContext context,
    required ChatInterfaceState state,
    required ChatInterfaceController controller,
  }) {
    // =======================================================================
    // INITIAL LOADING
    // =======================================================================

    if (state.isLoading && state.messages.isEmpty) {
      return const AppLoadingView(message: 'Loading conversation...');
    }

    // =======================================================================
    // INITIAL ERROR
    // =======================================================================

    if (state.errorMessage != null && state.messages.isEmpty) {
      return AppErrorView(
        error: state.errorMessage!,
        title: 'Unable to load conversation',
        message: 'The conversation could not be loaded.',
        onRetry: () {
          controller.findOrCreateConversation();
        },
      );
    }

    // =======================================================================
    // EMPTY
    // =======================================================================

    if (state.messages.isEmpty) {
      return EmptyState.noData(
        title: 'Start a conversation',
        description: 'Send a message to get started.',
        actionLabel: 'Write a message',
        onAction: () {
          _inputFocusNode.requestFocus();
        },
      );
    }

    // =======================================================================
    // MESSAGES
    // =======================================================================

    return RefreshIndicator(
      onRefresh: controller.loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];

          final previous = index > 0 ? state.messages[index - 1] : null;

          final showDateSeparator = _shouldShowDateSeparator(
            previous?.createdDate,
            message.createdDate,
          );

          final showSenderSpacing =
              previous != null && previous.sender != message.sender;

          return Column(
            children: [
              if (showDateSeparator)
                _DateSeparator(label: _formatMessageDate(message.createdDate)),

              if (showSenderSpacing) const SizedBox(height: AppSpacing.xs),

              _MessageBubble(
                message: message,
                currentUserId: controller.currentUserId,
                onCopy: () {
                  _copyMessage(context, message);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================================
  // SEND
  // =========================================================================

  Future<void> _sendMessage(ChatInterfaceController controller) async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final sent = await controller.sendTextMessage(text);

    if (!mounted || !sent) {
      return;
    }

    _textController.clear();

    _scrollToBottom();
  }

  // =========================================================================
  // MESSAGE ACTIONS
  // =========================================================================

  Future<void> _copyMessage(BuildContext context, Message message) async {
    final text = message.content.trim();

    if (text.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) {
      return;
    }

    AppMessage.success(
      context,
      'Message copied.',
      duration: const Duration(seconds: 2),
    );
  }

  // =========================================================================
  // SCROLL
  // =========================================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // =========================================================================
  // DATE
  // =========================================================================

  bool _shouldShowDateSeparator(DateTime? previous, DateTime? current) {
    if (current == null) {
      return false;
    }

    if (previous == null) {
      return true;
    }

    return previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day;
  }

  String _formatMessageDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final localDate = dateTime.toLocal();

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final date = DateTime(localDate.year, localDate.month, localDate.day);

    if (date == today) {
      return 'Today';
    }

    if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }
}

// ===========================================================================
// APP BAR TITLE
// ===========================================================================

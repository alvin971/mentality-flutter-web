import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/kepler_colors.dart';
import '../../../../core/widgets/et_logo_animated.dart';
import '../../../../core/widgets/kepler_app_bar.dart';
import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_event.dart';
import '../../bloc/chat_state.dart';

class MentalityChatPage extends StatelessWidget {
  const MentalityChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();
  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    context.read<ChatBloc>().add(SendMessageEvent(text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: KeplerAppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 8.w, right: 12.w),
          child: EtLogoAnimated(size: 32.w),
        ),
        title: context.l10n.appTitle,
        eyebrow: context.l10n.chatEyebrow,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh,
                size: 20.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            tooltip: context.l10n.chatNewConversation,
            onPressed: () =>
                context.read<ChatBloc>().add(const ClearConversationEvent()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (_, __) => _scrollToBottom(),
                builder: (context, state) {
                  final messages = state.messages;
                  final isLoading = state is ChatLoadingState;

                  if (messages.isEmpty && !isLoading) return _Empty();
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 16.h),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == messages.length && isLoading) {
                        return _LoadingBubble();
                      }
                      return _MessageBubble(message: messages[i]);
                    },
                  );
                },
              ),
            ),
            _InputBar(
              controller: _messageController,
              onSend: () => _sendMessage(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(context.l10n.chatAssistantLabel,
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
          SizedBox(height: 16.h),
          Text(context.l10n.chatHeroTitle1, style: AppText.of(context).heroDisplay()),
          Text(context.l10n.chatHeroTitle2, style: AppText.of(context).heroItalic()),
          SizedBox(height: 16.h),
          Container(
            width: 40.w,
            height: 1,
            color: KeplerColors.of(context).primary.withValues(alpha: 0.4),
          ),
          SizedBox(height: 16.h),
          Text(
            context.l10n.chatEmptyIntro,
            style: AppText.of(context).body(),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  String _ts(BuildContext context, DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return context.l10n.chatTimeJustNow;
    if (d.inHours < 1) return context.l10n.chatTimeMinutes(d.inMinutes);
    if (d.inDays < 1) return context.l10n.chatTimeHours(d.inHours);
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    final err = message.isError;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment:
            user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(user ? context.l10n.chatUserLabel : context.l10n.chatAssistantLabel,
              style: AppText.of(context).monoLabel(
                  color: err
                      ? AppColors.error
                      : (user
                          ? Theme.of(context).colorScheme.outline
                          : AppColors.primary))),
          SizedBox(height: 6.h),
          Container(
            constraints: BoxConstraints(maxWidth: 320.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: user
                  ? AppColors.primary
                  : err
                      ? AppColors.error.withValues(alpha: 0.08)
                      : Theme.of(context).colorScheme.surface,
              border: user
                  ? null
                  : Border.all(color: Colors.black.withValues(alpha: 0.07)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              message.text,
              style: AppText.of(context).body(
                color: user
                    ? Theme.of(context).scaffoldBackgroundColor
                    : err
                        ? AppColors.error
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(_ts(context, message.timestamp),
              style: AppText.of(context).monoLabel(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.chatAssistantLabel,
              style: AppText.of(context).monoLabel(color: KeplerColors.of(context).primary)),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KeplerColors.of(context).primary,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(context.l10n.chatThinking,
                    style: AppText.of(context).body(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isLoading = state is ChatLoadingState;
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isLoading,
                    style: AppText.of(context).body(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: context.l10n.chatInputHint,
                      hintStyle:
                          AppText.of(context).body(color: Theme.of(context).colorScheme.outline),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.07)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.07)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(
                            color: KeplerColors.of(context).primary, width: 2),
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                SizedBox(width: 10.w),
                Material(
                  color: KeplerColors.of(context).primary,
                  borderRadius: BorderRadius.circular(6.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6.r),
                    onTap: isLoading ? null : onSend,
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Icon(Icons.arrow_upward,
                          color: Theme.of(context).scaffoldBackgroundColor, size: 20.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Modèle de message de chat — partagé entre la UI et le BLoC.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

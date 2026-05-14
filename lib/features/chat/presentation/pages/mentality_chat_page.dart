import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
      backgroundColor: AppColors.background,
      appBar: KeplerAppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 8.w, right: 12.w),
          child: EtLogoAnimated(size: 32.w),
        ),
        title: 'Mentality',
        eyebrow: 'ASSISTANT IA',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh,
                size: 20.sp, color: AppColors.textSecondary),
            tooltip: 'Nouvelle conversation',
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
          Text('MENTALITY',
              style: AppText.monoLabel(color: AppColors.primary)),
          SizedBox(height: 16.h),
          Text('Posez', style: AppText.heroDisplay()),
          Text('vos questions.', style: AppText.heroItalic()),
          SizedBox(height: 16.h),
          Container(
            width: 40.w,
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          SizedBox(height: 16.h),
          Text(
            'L\'IA Mentality vous aide à mieux comprendre votre profil cognitif. '
            'Discussions confidentielles, accompagnement non-directif.',
            style: AppText.body(),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  String _ts(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'à l\'instant';
    if (d.inHours < 1) return '${d.inMinutes} min';
    if (d.inDays < 1) return '${d.inHours}h';
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
          Text(user ? 'VOUS' : 'MENTALITY',
              style: AppText.monoLabel(
                  color: err
                      ? AppColors.error
                      : (user
                          ? AppColors.textTertiary
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
                      : AppColors.white,
              border: user
                  ? null
                  : Border.all(color: Colors.black.withValues(alpha: 0.07)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              message.text,
              style: AppText.body(
                color: user
                    ? AppColors.background
                    : err
                        ? AppColors.error
                        : AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(_ts(message.timestamp),
              style: AppText.monoLabel(color: AppColors.textTertiary)),
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
          Text('MENTALITY',
              style: AppText.monoLabel(color: AppColors.primary)),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10.w),
                Text('Réflexion…',
                    style: AppText.body(color: AppColors.textSecondary)),
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
            color: AppColors.background,
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
                    style: AppText.body(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Écrire un message…',
                      hintStyle:
                          AppText.body(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.white,
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
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                SizedBox(width: 10.w),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6.r),
                    onTap: isLoading ? null : onSend,
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Icon(Icons.arrow_upward,
                          color: AppColors.background, size: 20.sp),
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

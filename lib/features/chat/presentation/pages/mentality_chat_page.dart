import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_event.dart';
import '../../bloc/chat_state.dart';

/// Page de chat avec l'assistant IA Mentality (Claude via Cloudflare Worker).
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
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.psychology, size: 20.sp, color: AppColors.tertiary),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mentality',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                Text('Assistant IA',
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.normal,
                        color: AppColors.grey600)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nouvelle conversation',
            onPressed: () =>
                context.read<ChatBloc>().add(const ClearConversationEvent()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                // Scroll vers le bas à chaque nouveau message
                _scrollToBottom();
              },
              builder: (context, state) {
                final messages = state.messages;
                final isLoading = state is ChatLoadingState;

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16.w),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == messages.length && isLoading) {
                          return _buildLoadingBubble();
                        }
                        return _buildMessageBubble(messages[i]);
                      },
                    ),
                    if (messages.isEmpty && !isLoading)
                      Center(
                        child: Text(
                          'Mentality, l\'IA qui t\'aide à mieux te comprendre',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.grey400,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isLoading = state is ChatLoadingState;
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Envoyer un message...',
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(context),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 24.sp),
                    onPressed: isLoading ? null : () => _sendMessage(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        constraints: BoxConstraints(maxWidth: 280.w),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : message.isError
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.grey100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft:
                      message.isUser ? Radius.circular(16.r) : Radius.zero,
                  bottomRight:
                      message.isUser ? Radius.zero : Radius.circular(16.r),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: message.isUser
                      ? Colors.white
                      : message.isError
                          ? AppColors.error
                          : AppColors.grey900,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(fontSize: 10.sp, color: AppColors.grey500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomRight: Radius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Écrit...',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.grey600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${timestamp.day}/${timestamp.month}';
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

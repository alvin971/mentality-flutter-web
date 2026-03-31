import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_event.dart';
import '../../bloc/chat_state.dart';

// Couleurs du dark theme chat
const _kChatBg = Color(0xFF0B1F17);
const _kChatSurface = Color(0xFF132B1F);
const _kAiBubble = Color(0xFF1A2E22);
const _kUserBubble = Color(0xFF3D6B3A);
const _kInputFill = Color(0xFF132B1F);

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
      backgroundColor: _kChatBg,
      appBar: AppBar(
        backgroundColor: _kChatBg,
        foregroundColor: Colors.white,
        titleSpacing: 16.w,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 20.sp),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: _kChatBg, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mentality',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '• En ligne',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF4ADE80),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            tooltip: 'Nouvelle conversation',
            onPressed: () =>
                context.read<ChatBloc>().add(const ClearConversationEvent()),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                _scrollToBottom();
              },
              builder: (context, state) {
                final messages = state.messages;
                final isLoading = state is ChatLoadingState;

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
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
                          'Un espace d\'écoute disponible 24h/24',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white24,
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
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          color: _kChatSurface,
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !isLoading,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre message...',
                      hintStyle:
                          const TextStyle(color: Colors.white38, fontSize: 14),
                      filled: true,
                      fillColor: _kInputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: const BorderSide(
                            color: AppColors.secondary, width: 1.5),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 12.h,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(context),
                  ),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: isLoading ? null : () => _sendMessage(context),
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20.sp,
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

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
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
                    ? _kUserBubble
                    : message.isError
                        ? AppColors.error.withOpacity(0.2)
                        : _kAiBubble,
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
                  color: message.isError
                      ? AppColors.errorLight
                      : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(fontSize: 10.sp, color: Colors.white24),
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
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: _kAiBubble,
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Écrit...',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white54,
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

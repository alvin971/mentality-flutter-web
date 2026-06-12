import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/l10n_ext.dart';
import '../presentation/pages/mentality_chat_page.dart';
import '../presentation/services/claude_chat_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC qui gère la conversation avec l'assistant IA Claude.
///
/// Séparation claire entre la logique métier (appel API, gestion historique)
/// et la présentation (MentalityChatPage).
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ClaudeChatService _service;

  ChatBloc({ClaudeChatService? service})
      : _service = service ?? ClaudeChatService(),
        super(const ChatIdleState([])) {
    on<SendMessageEvent>(_onSend);
    on<ClearConversationEvent>(_onClear);
  }

  Future<void> _onSend(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = ChatMessage(
      text: event.text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    emit(ChatLoadingState(updatedMessages));

    try {
      final response = await _service.sendMessage(
        message: event.text,
        conversationHistory: state.messages,
      );

      final assistantMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(ChatIdleState([...updatedMessages, assistantMessage]));
    } catch (e) {
      final errorMessage = ChatMessage(
        text: appL10n.chatErrorMessage,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      emit(ChatErrorState(
        [...updatedMessages, errorMessage],
        e.toString(),
      ));
    }
  }

  void _onClear(
    ClearConversationEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(const ChatIdleState([]));
  }
}

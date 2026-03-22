import 'package:equatable/equatable.dart';
import '../presentation/pages/mentality_chat_page.dart';

abstract class ChatState extends Equatable {
  final List<ChatMessage> messages;
  const ChatState(this.messages);
  @override
  List<Object?> get props => [messages];
}

/// État initial / idle (pas de requête en cours)
class ChatIdleState extends ChatState {
  const ChatIdleState(super.messages);
}

/// Requête API en cours — l'IA est en train de répondre
class ChatLoadingState extends ChatState {
  const ChatLoadingState(super.messages);
}

/// Erreur lors de l'envoi / réception
class ChatErrorState extends ChatState {
  final String error;
  const ChatErrorState(super.messages, this.error);
  @override
  List<Object?> get props => [...super.props, error];
}

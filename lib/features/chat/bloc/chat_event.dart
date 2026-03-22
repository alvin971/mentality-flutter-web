import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

/// L'utilisateur envoie un message.
class SendMessageEvent extends ChatEvent {
  final String text;
  const SendMessageEvent(this.text);
  @override
  List<Object?> get props => [text];
}

/// L'utilisateur réinitialise la conversation.
class ClearConversationEvent extends ChatEvent {
  const ClearConversationEvent();
}

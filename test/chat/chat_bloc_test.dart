import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentality/features/chat/bloc/chat_bloc.dart';
import 'package:mentality/features/chat/bloc/chat_event.dart';
import 'package:mentality/features/chat/bloc/chat_state.dart';
import 'package:mentality/features/chat/presentation/pages/mentality_chat_page.dart';

/// Mock du service Claude qui retourne une réponse fixe.
class _MockChatService extends Fake {
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> conversationHistory,
  }) async {
    return 'Réponse de test pour : $message';
  }
}

// Nous ne pouvons pas injecter facilement le service mock sans modifier ChatBloc
// car il crée ClaudeChatService() directement.
// Ces tests vérifient la logique d'état pure (ClearConversationEvent).

void main() {
  group('ChatBloc', () {
    test('état initial est ChatIdleState avec liste vide', () {
      final bloc = ChatBloc();
      expect(bloc.state, isA<ChatIdleState>());
      expect(bloc.state.messages, isEmpty);
      bloc.close();
    });

    blocTest<ChatBloc, ChatState>(
      'ClearConversationEvent vide la liste des messages',
      build: () => ChatBloc(),
      act: (bloc) => bloc.add(const ClearConversationEvent()),
      expect: () => [
        isA<ChatIdleState>().having((s) => s.messages, 'messages', isEmpty),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'ClearConversationEvent après plusieurs états repart à zéro',
      build: () => ChatBloc(),
      seed: () => ChatIdleState([
        ChatMessage(text: 'test', isUser: true, timestamp: DateTime.now()),
      ]),
      act: (bloc) => bloc.add(const ClearConversationEvent()),
      expect: () => [
        isA<ChatIdleState>().having((s) => s.messages, 'messages', isEmpty),
      ],
    );
  });

  group('ChatState', () {
    test('ChatIdleState.messages retourne la liste fournie', () {
      final msgs = [
        ChatMessage(text: 'hello', isUser: true, timestamp: DateTime.now()),
      ];
      final state = ChatIdleState(msgs);
      expect(state.messages, equals(msgs));
    });

    test('ChatLoadingState indique un chargement en cours', () {
      final state = ChatLoadingState(const []);
      expect(state, isA<ChatLoadingState>());
    });

    test('ChatErrorState contient le message d\'erreur', () {
      const error = 'Worker non configuré';
      final state = ChatErrorState(const [], error);
      expect(state.error, equals(error));
    });
  });

  group('ChatMessage', () {
    test('isError vaut false par défaut', () {
      final msg = ChatMessage(
        text: 'hello',
        isUser: true,
        timestamp: DateTime.now(),
      );
      expect(msg.isError, isFalse);
    });

    test('message d\'erreur a isError = true', () {
      final msg = ChatMessage(
        text: 'erreur',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      expect(msg.isError, isTrue);
    });
  });
}

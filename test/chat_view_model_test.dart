import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finance_mobile/viewmodels/chat_view_model.dart';
import 'package:app_finance_mobile/repositories/chat_repository.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';
import 'package:app_finance_mobile/services/api_service.dart';
import 'package:app_finance_mobile/models/transaction.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockChatRepository extends ChatRepository {
  MockChatRepository()
      : super(
          apiService: ApiService(
            client: MockClient((_) async => http.Response('', 200)),
          ),
        );

  Future<Map<String, dynamic>> Function(String message)? onSendMessage;

  @override
  Future<Map<String, dynamic>> sendMessage(String message) async {
    if (onSendMessage != null) {
      return onSendMessage!(message);
    }
    return {
      'isTransaction': false,
      'reply': 'Mock response',
    };
  }
}

class MockTransactionRepository extends TransactionRepository {
  MockTransactionRepository()
      : super(
          apiService: ApiService(
            client: MockClient((_) async => http.Response('', 200)),
          ),
        );

  Future<Transaction> Function({
    required String description,
    required double amount,
    required String type,
    required String date,
    String? categoryId,
    String? paymentMethod,
    int? installments,
  })? onCreateTransaction;

  @override
  Future<Transaction> createTransaction({
    required String description,
    required double amount,
    required String type,
    required String date,
    String? categoryId,
    String? paymentMethod,
    int? installments,
  }) async {
    if (onCreateTransaction != null) {
      return onCreateTransaction!(
        description: description,
        amount: amount,
        type: type,
        date: date,
        categoryId: categoryId,
        paymentMethod: paymentMethod,
        installments: installments,
      );
    }
    return Transaction(
      id: 'mock_tx',
      name: description,
      category: 'Alimentação',
      amount: amount,
      date: date,
      status: 'Completed',
    );
  }
}

void main() {
  late MockChatRepository mockChatRepository;
  late MockTransactionRepository mockTransactionRepository;
  late ChatViewModel viewModel;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    mockChatRepository = MockChatRepository();
    mockTransactionRepository = MockTransactionRepository();
    viewModel = ChatViewModel(
      chatRepository: mockChatRepository,
      transactionRepository: mockTransactionRepository,
    );
  });

  group('ChatViewModel Tests', () {
    test('Initial state contains welcome message after initialization', () async {
      expect(viewModel.messages.isEmpty, true);

      await viewModel.initializeWelcomeMessage('Welcome to AI Chat!');

      expect(viewModel.messages.length, 1);
      expect(viewModel.messages[0].text, 'Welcome to AI Chat!');
      expect(viewModel.messages[0].isUser, false);
    });

    test('sendMessage handles non-transaction dialogue correctly', () async {
      mockChatRepository.onSendMessage = (msg) async {
        return {
          'isTransaction': false,
          'reply': 'Hello! I can help you log transactions.',
        };
      };

      await viewModel.sendMessage('Hi assistant');

      // Should have: user message and then AI response
      expect(viewModel.messages.length, 2);
      expect(viewModel.messages[0].text, 'Hi assistant');
      expect(viewModel.messages[0].isUser, true);

      expect(viewModel.messages[1].text, 'Hello! I can help you log transactions.');
      expect(viewModel.messages[1].isUser, false);
      expect(viewModel.messages[1].transactionData, null);
    });

    test('sendMessage handles structured transaction correctly', () async {
      mockChatRepository.onSendMessage = (msg) async {
        return {
          'isTransaction': true,
          'amount': 45.0,
          'description': 'Almoço com amigos',
          'type': 'EXPENSE',
          'categoryName': 'Alimentação',
          'categoryId': 'food_uuid_123',
          'date': '2026-09-04T12:00:00.000Z',
          'reply': 'Entendi! Registrei R\$ 45,00 em Alimentação.',
        };
      };

      await viewModel.sendMessage('Gastei 45 no almoço');

      expect(viewModel.messages.length, 2);
      final aiMsg = viewModel.messages[1];
      expect(aiMsg.text, 'Entendi! Registrei R\$ 45,00 em Alimentação.');
      expect(aiMsg.transactionData != null, true);
      expect(aiMsg.transactionData!['amount'], 45.0);
      expect(aiMsg.transactionData!['categoryId'], 'food_uuid_123');
      expect(aiMsg.transactionData!['type'], 'EXPENSE');
    });

    test('confirmTransaction calls transaction creation and marks message as confirmed', () async {
      final chatMessage = ChatMessage(
        text: 'Lançar despesa',
        isUser: false,
        transactionData: {
          'amount': 45.0,
          'description': 'Almoço com amigos',
          'type': 'EXPENSE',
          'categoryName': 'Alimentação',
          'categoryId': 'food_uuid_123',
          'date': '2026-09-04T12:00:00.000Z',
        },
      );

      bool createCalled = false;
      mockTransactionRepository.onCreateTransaction = ({
        required description,
        required amount,
        required type,
        required date,
        categoryId,
        paymentMethod,
        installments,
      }) async {
        createCalled = true;
        expect(description, 'Almoço com amigos');
        expect(amount, 45.0);
        expect(type, 'EXPENSE');
        expect(categoryId, 'food_uuid_123');
        return Transaction(
          id: 'mock_tx',
          name: description,
          category: 'Alimentação',
          amount: amount,
          date: date,
          status: 'Completed',
        );
      };

      final success = await viewModel.confirmTransaction(chatMessage);

      expect(success, true);
      expect(createCalled, true);
      expect(chatMessage.isConfirmed, true);
      expect(chatMessage.isCancelled, false);
    });

    test('cancelTransaction marks message as cancelled', () {
      final chatMessage = ChatMessage(
        text: 'Lançar despesa',
        isUser: false,
        transactionData: {
          'amount': 45.0,
          'description': 'Almoço com amigos',
          'type': 'EXPENSE',
        },
      );

      viewModel.cancelTransaction(chatMessage);

      expect(chatMessage.isConfirmed, false);
      expect(chatMessage.isCancelled, true);
    });
  });
}

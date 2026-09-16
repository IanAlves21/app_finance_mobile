import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finance_mobile/viewmodels/chat_view_model.dart';
import 'package:app_finance_mobile/repositories/chat_repository.dart';
import 'package:app_finance_mobile/repositories/transaction_repository.dart';
import 'package:app_finance_mobile/repositories/category_repository.dart';
import 'package:app_finance_mobile/models/category.dart';
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

class MockCategoryRepository extends CategoryRepository {
  MockCategoryRepository()
      : super(
          apiService: ApiService(
            client: MockClient((_) async => http.Response('', 200)),
          ),
        );

  Future<List<Category>> Function()? onFetchCategories;

  @override
  Future<List<Category>> fetchCategories() async {
    if (onFetchCategories != null) {
      return onFetchCategories!();
    }
    return [];
  }
}

void main() {
  late MockChatRepository mockChatRepository;
  late MockTransactionRepository mockTransactionRepository;
  late MockCategoryRepository mockCategoryRepository;
  late ChatViewModel viewModel;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    mockChatRepository = MockChatRepository();
    mockTransactionRepository = MockTransactionRepository();
    mockCategoryRepository = MockCategoryRepository();
    viewModel = ChatViewModel(
      chatRepository: mockChatRepository,
      transactionRepository: mockTransactionRepository,
      categoryRepository: mockCategoryRepository,
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

    test('initializeWelcomeMessage fetches and stores user categories', () async {
      mockCategoryRepository.onFetchCategories = () async {
        return [
          const Category(
            id: 'food_uuid_123',
            name: 'Alimentação',
            type: 'EXPENSE',
            icon: 'food',
            color: '#de350b',
          ),
          const Category(
            id: 'shopping_uuid_456',
            name: 'Compras',
            type: 'EXPENSE',
            icon: 'shopping-cart',
            color: '#00875a',
          ),
        ];
      };

      expect(viewModel.categories.isEmpty, true);

      await viewModel.initializeWelcomeMessage('Welcome to AI Chat!');

      expect(viewModel.categories.length, 2);
      expect(viewModel.categories[0].id, 'food_uuid_123');
      expect(viewModel.categories[0].name, 'Alimentação');
      expect(viewModel.categories[1].name, 'Compras');
    });

    test('sendMessage triggers category fetch if categories list is empty', () async {
      bool categoriesFetched = false;
      mockCategoryRepository.onFetchCategories = () async {
        categoriesFetched = true;
        return [
          const Category(
            id: 'leisure_uuid_789',
            name: 'Lazer',
            type: 'EXPENSE',
            icon: 'entertainment',
            color: '#ffc107',
          ),
        ];
      };

      mockChatRepository.onSendMessage = (msg) async {
        return {
          'isTransaction': false,
          'reply': 'Qualquer resposta',
        };
      };

      expect(viewModel.categories.isEmpty, true);

      await viewModel.sendMessage('Gastei com cinema');

      expect(categoriesFetched, true);
      expect(viewModel.categories.length, 1);
      expect(viewModel.categories[0].name, 'Lazer');
    });

    test('sendMessage detects payment method and credit card installments from user message', () async {
      mockCategoryRepository.onFetchCategories = () async => [];
      mockChatRepository.onSendMessage = (msg) async {
        return {
          'isTransaction': true,
          'amount': 350.0,
          'description': 'Geladeira nova',
          'type': 'EXPENSE',
          'categoryName': 'Casa',
          'categoryId': 'home_uuid_123',
          'date': '2026-09-04T12:00:00.000Z',
          'reply': 'Entendi! Lançando Geladeira nova.',
        };
      };

      // Teste 1: Crédito parcelado
      await viewModel.sendMessage('Comprei no crédito em 10 vezes uma geladeira');
      final msg1 = viewModel.messages.last;
      expect(msg1.transactionData != null, true);
      expect(msg1.transactionData!['paymentMethod'], 'CREDIT');
      expect(msg1.transactionData!['installments'], 10);

      // Teste 2: Pix
      await viewModel.sendMessage('Gastei 15 no pix pro almoço');
      final msg2 = viewModel.messages.last;
      expect(msg2.transactionData != null, true);
      expect(msg2.transactionData!['paymentMethod'], 'PIX');
      expect(msg2.transactionData!['installments'], null);
    });

    test('updatePaymentMethod and updateInstallments update message state correctly', () {
      final chatMessage = ChatMessage(
        text: 'Lançar',
        isUser: false,
        transactionData: {
          'amount': 100.0,
          'description': 'Compra',
          'type': 'EXPENSE',
          'paymentMethod': 'CASH',
        },
      );

      viewModel.updatePaymentMethod(chatMessage, 'CREDIT');
      expect(chatMessage.transactionData!['paymentMethod'], 'CREDIT');
      expect(chatMessage.transactionData!['installments'], 1); // Garante que inicializa em 1 se for CREDIT

      viewModel.updateInstallments(chatMessage, 5);
      expect(chatMessage.transactionData!['installments'], 5);

      viewModel.updatePaymentMethod(chatMessage, 'PIX');
      expect(chatMessage.transactionData!['paymentMethod'], 'PIX');
      expect(chatMessage.transactionData!['installments'], null); // Remove parcelas se não for crédito
    });

    test('sendMessage handles raw system or JSON error replies with friendly Portuguese sanitization', () async {
      mockCategoryRepository.onFetchCategories = () async => [];
      mockChatRepository.onSendMessage = (msg) async {
        return {
          'isTransaction': false,
          'reply': 'Erro na API do Gemini: 500 - {"error": {"code": 500, "message": "API key blocked", "status": "INTERNAL"}}',
        };
      };

      await viewModel.sendMessage('Oi assistente');
      final errMessage = viewModel.messages.last;
      expect(errMessage.isUser, false);
      expect(errMessage.text.contains('indisponível') || errMessage.text.contains('instabilidade'), true);
      expect(errMessage.text.contains('{"error":'), false); // Sem JSON feio!
    });
  });
}

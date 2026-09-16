import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/chat_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/category_repository.dart';
import '../models/category.dart';
import '../services/service_locator.dart';
import '../utils/ui_utils.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? transactionData; // Estrutura enviada pelo Gemini
  bool isConfirmed;
  bool isCancelled;
  bool isActionLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.transactionData,
    this.isConfirmed = false,
    this.isCancelled = false,
    this.isActionLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'transactionData': transactionData,
      'isConfirmed': isConfirmed,
      'isCancelled': isCancelled,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      transactionData: json['transactionData'] != null
          ? Map<String, dynamic>.from(json['transactionData'] as Map)
          : null,
      isConfirmed: json['isConfirmed'] as bool? ?? false,
      isCancelled: json['isCancelled'] as bool? ?? false,
    );
  }
}

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  List<Category> _categories = [];

  ChatViewModel({
    ChatRepository? chatRepository,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  })  : _chatRepository = chatRepository ?? locator<ChatRepository>(),
        _transactionRepository =
            transactionRepository ?? locator<TransactionRepository>(),
        _categoryRepository =
            categoryRepository ?? locator<CategoryRepository>();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Category> get categories => _categories;

  /// Inicializa o chat carregando o histórico persistido do SharedPreferences
  Future<void> initializeWelcomeMessage(String welcomeText) async {
    try {
      _categories = await _categoryRepository.fetchCategories();
    } catch (e) {
      debugPrint('Erro ao carregar categorias no ChatViewModel: $e');
    }

    if (_messages.isNotEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedHistory = prefs.getString('chat_history');

      if (cachedHistory != null && cachedHistory.isNotEmpty) {
        final List<dynamic> list = json.decode(cachedHistory);
        _messages.clear();
        _messages.addAll(
          list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)),
        );
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Erro ao carregar histórico local do chat: $e');
    }

    _messages.add(ChatMessage(
      text: welcomeText,
      isUser: false,
    ));
    notifyListeners();
  }

  /// Salva o histórico atual do chat localmente de forma persistente
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(_messages.map((m) => m.toJson()).toList());
      await prefs.setString('chat_history', encoded);
    } catch (e) {
      debugPrint('Erro ao persistir histórico do chat: $e');
    }
  }

  /// Envia a mensagem do usuário para processamento inteligente
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (_categories.isEmpty) {
      try {
        _categories = await _categoryRepository.fetchCategories();
      } catch (_) {}
    }

    // 1. Adiciona a mensagem do usuário e persiste
    _messages.add(ChatMessage(text: text, isUser: true));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _saveHistory();

    try {
      // 2. Envia para o backend processar com Gemini
      final response = await _chatRepository.sendMessage(text);

      final isTransaction = response['isTransaction'] as bool? ?? false;
      final String reply = response['reply'] as String? ?? 'Desculpe, não entendi.';
      final String cleanReply = _sanitizeReply(reply);

      Map<String, dynamic>? transactionData;
      if (isTransaction) {
        final detectedPaymentMethod = _detectPaymentMethod(text, response['type']?.toString() ?? 'EXPENSE');
        final detectedInstallments = _detectInstallments(text, detectedPaymentMethod);
        transactionData = {
          'amount': response['amount'],
          'description': response['description'],
          'type': response['type'],
          'categoryName': response['categoryName'],
          'categoryId': response['categoryId'],
          'date': response['date'],
          'paymentMethod': detectedPaymentMethod,
          'installments': detectedInstallments,
        };
      }

      // 3. Adiciona a resposta da IA e persiste
      _messages.add(ChatMessage(
        text: cleanReply,
        isUser: false,
        transactionData: transactionData,
      ));
      await _saveHistory();
    } catch (e) {
      _errorMessage = UIUtils.sanitizeErrorMessage(e);
      _messages.add(ChatMessage(
        text: 'Desculpe, tive um problema para me conectar. Por favor, tente novamente.',
        isUser: false,
      ));
      await _saveHistory();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Higieniza e traduz respostas com erros ou contendo JSON para mensagens amigáveis ao usuário
  String _sanitizeReply(String reply) {
    if (reply.contains('{') && reply.contains('}')) {
      final clean = UIUtils.sanitizeErrorMessage(reply);
      final lower = clean.toLowerCase();
      if (clean.contains('Erro na API') || 
          clean.contains('Gemini') || 
          clean.contains('assistente') ||
          lower.contains('blocked') ||
          lower.contains('key') ||
          lower.contains('api') ||
          lower.contains('unauthorized') ||
          lower.contains('invalid')) {
        return 'Desculpe, o assistente inteligente está indisponível ou em manutenção no momento. Por favor, tente novamente em instantes.';
      }
      return clean;
    }
    if (reply.contains('Error') || reply.contains('Exception') || reply.contains('failed') || reply.contains('Gemini:')) {
      return 'Desculpe, o assistente encontrou uma instabilidade ao processar sua mensagem. Por favor, tente novamente.';
    }
    return reply;
  }

  /// Detecta de forma inteligente a forma de pagamento a partir do texto do usuário
  String? _detectPaymentMethod(String text, String type) {
    if (type == 'INCOME') return null;
    final lower = text.toLowerCase();
    if (lower.contains('crédito') || lower.contains('credito') || lower.contains('cartão') || lower.contains('cartao')) {
      return 'CREDIT';
    }
    if (lower.contains('débito') || lower.contains('debito')) {
      return 'DEBIT';
    }
    if (lower.contains('pix')) {
      return 'PIX';
    }
    if (lower.contains('dinheiro') || lower.contains('espécie') || lower.contains('especie') || lower.contains('cash')) {
      return 'CASH';
    }
    return 'CASH'; // Fallback padrão
  }

  /// Detecta de forma inteligente o número de parcelas a partir do texto do usuário para crédito
  int? _detectInstallments(String text, String? paymentMethod) {
    if (paymentMethod != 'CREDIT') return null;
    
    final lower = text.toLowerCase();
    
    // Procura padrões como "3x", "3 x", "em 3 vezes", "em 3 vez", "3 parcelas", "3 parcela", "parcelado em 3"
    final regexes = [
      RegExp(r'(\d+)\s*x'),
      RegExp(r'em\s+(\d+)\s*(vezes|vez)'),
      RegExp(r'(\d+)\s*(parcelas|parcela)'),
      RegExp(r'parcelado\s+em\s+(\d+)'),
    ];
    
    for (final reg in regexes) {
      final match = reg.firstMatch(lower);
      if (match != null) {
        final String? digits = match.group(1);
        if (digits != null) {
          final int? value = int.tryParse(digits);
          if (value != null && value > 1) {
            return value;
          }
        }
      }
    }
    return null;
  }

  /// Permite ao usuário alterar a forma de pagamento diretamente no card de transação do chat
  void updatePaymentMethod(ChatMessage msg, String paymentMethod) {
    if (msg.transactionData != null) {
      msg.transactionData!['paymentMethod'] = paymentMethod;
      // Garante parcelas adequadas ao mudar para crédito ou outras formas
      if (paymentMethod == 'CREDIT') {
        msg.transactionData!['installments'] ??= 1;
      } else {
        msg.transactionData!.remove('installments');
      }
      notifyListeners();
      _saveHistory();
    }
  }

  /// Permite ao usuário alterar o número de parcelas diretamente no card de transação do chat
  void updateInstallments(ChatMessage msg, int installments) {
    if (msg.transactionData != null) {
      msg.transactionData!['installments'] = installments;
      notifyListeners();
      _saveHistory();
    }
  }

  /// Confirma e lança a transação financeira estruturada pela IA no banco de dados
  Future<bool> confirmTransaction(ChatMessage message) async {
    final data = message.transactionData;
    if (data == null || message.isConfirmed || message.isCancelled) return false;

    message.isActionLoading = true;
    notifyListeners();

    try {
      final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final String description = data['description'] as String? ?? 'Lançamento IA';
      final String type = data['type'] as String? ?? 'EXPENSE';
      final String? categoryId = data['categoryId'] as String?;
      final String dateStr = data['date'] as String? ?? DateTime.now().toIso8601String();
      final String? paymentMethod = data['paymentMethod'] as String?;
      final int? installments = data['installments'] as int?;

      // Chama a inserção de transação padrão
      await _transactionRepository.createTransaction(
        description: description,
        amount: amount,
        type: type,
        date: dateStr,
        categoryId: categoryId,
        paymentMethod: paymentMethod,
        installments: installments,
      );

      message.isConfirmed = true;
      notifyListeners();
      await _saveHistory(); // Salva novo estado do card ("Confirmado") no histórico
      return true;
    } catch (e) {
      debugPrint('Erro ao confirmar transação via IA: $e');
      message.isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancela o card de confirmação de transação no chat
  Future<void> cancelTransaction(ChatMessage message) async {
    if (message.isConfirmed || message.isCancelled) return;
    message.isCancelled = true;
    notifyListeners();
    await _saveHistory(); // Salva novo estado do card ("Descartado") no histórico
  }

  /// Limpa as mensagens do chat e do SharedPreferences
  Future<void> clearChat(String welcomeText) async {
    _messages.clear();
    _messages.add(ChatMessage(text: welcomeText, isUser: false));
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
    } catch (e) {
      debugPrint('Erro ao limpar cache do chat: $e');
    }
  }
}

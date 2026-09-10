import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/chat_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/service_locator.dart';

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

  ChatViewModel({
    ChatRepository? chatRepository,
    TransactionRepository? transactionRepository,
  })  : _chatRepository = chatRepository ?? locator<ChatRepository>(),
        _transactionRepository =
            transactionRepository ?? locator<TransactionRepository>();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Inicializa o chat carregando o histórico persistido do SharedPreferences
  Future<void> initializeWelcomeMessage(String welcomeText) async {
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

      Map<String, dynamic>? transactionData;
      if (isTransaction) {
        transactionData = {
          'amount': response['amount'],
          'description': response['description'],
          'type': response['type'],
          'categoryName': response['categoryName'],
          'categoryId': response['categoryId'],
          'date': response['date'],
        };
      }

      // 3. Adiciona a resposta da IA e persiste
      _messages.add(ChatMessage(
        text: reply,
        isUser: false,
        transactionData: transactionData,
      ));
      await _saveHistory();
    } catch (e) {
      _errorMessage = e.toString();
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

      // Chama a inserção de transação padrão
      await _transactionRepository.createTransaction(
        description: description,
        amount: amount,
        type: type,
        date: dateStr,
        categoryId: categoryId,
        paymentMethod: type == 'EXPENSE' ? 'CASH' : null,
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

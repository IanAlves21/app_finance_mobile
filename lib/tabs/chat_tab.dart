import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../services/service_locator.dart';
import '../viewmodels/chat_view_model.dart';
import '../utils/currency_formatter.dart';
import '../widgets/custom_toast.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  late final ChatViewModel _viewModel;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = locator<ChatViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context)!;
      _viewModel.initializeWelcomeMessage(l10n.aiAssistantWelcome);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await _viewModel.sendMessage(text);
    _scrollToBottom();
  }

  IconData _getCategoryIcon(String? iconName) {
    if (iconName == null) return Icons.category_rounded;
    switch (iconName.toLowerCase()) {
      case 'shopping':
      case 'shopping-cart':
      case 'compras':
        return Icons.shopping_bag_rounded;
      case 'food':
      case 'fooddining':
      case 'restaurant':
      case 'alimentação':
      case 'comida':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'transportation':
      case 'car':
      case 'transporte':
        return Icons.directions_car_rounded;
      case 'leisure':
      case 'lazer':
      case 'entertainment':
        return Icons.sports_esports_rounded;
      case 'health':
      case 'saúde':
        return Icons.medical_services_rounded;
      case 'education':
      case 'educação':
        return Icons.school_rounded;
      case 'home':
      case 'moradia':
      case 'utilities':
        return Icons.home_rounded;
      case 'briefcase':
      case 'income':
      case 'salário':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.darkSlate;
    final l10n = AppLocalizations.of(context)!;

    final SystemUiOverlayStyle overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: AppColors.darkCard,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        // Scroll automático ao carregar ou receber nova mensagem
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppColors.accentOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.wallets, // Mudamos no .arb para "Assistente IA"
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: textColor,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, size: 22),
                  tooltip: 'Limpar Conversa',
                  onPressed: () {
                    _viewModel.clearChat(l10n.aiAssistantWelcome);
                    CustomToast.showSuccess(context, 'Histórico de chat limpo!');
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: [
                // Lista de mensagens
                Expanded(
                  child: _viewModel.messages.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _viewModel.messages.length,
                          itemBuilder: (context, index) {
                            final msg = _viewModel.messages[index];
                            return _buildMessageItem(msg, isDark);
                          },
                        ),
                ),

                // Indicador visual de carregamento / digitando
                if (_viewModel.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isDark ? 'Analisando...' : 'Analisando...',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Input de Texto fixo embaixo
                _buildInputSection(isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(ChatMessage msg, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final alignment = msg.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = msg.isUser
        ? AppColors.accentOrange
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final textColor = msg.isUser ? Colors.white : (isDark ? Colors.white : AppColors.darkSlate);

    final borderRadius = msg.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          child: Column(
            crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Bolha do chat com texto
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
              ),

              // Se houver dados estruturados de transação, renderiza o Card de Confirmação Rápida!
              if (msg.transactionData != null) ...[
                const SizedBox(height: 8),
                _buildTransactionConfirmationCard(msg, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionConfirmationCard(ChatMessage msg, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final data = msg.transactionData!;
    final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final String description = data['description'] as String? ?? 'Sem descrição';
    final String type = data['type'] as String? ?? 'EXPENSE';
    final String categoryName = data['categoryName'] as String? ?? 'Outros';
    final String? iconName = data['categoryId'] != null ? categoryName : null;

    final isExpense = type == 'EXPENSE';
    final statusColor = isExpense ? AppColors.redAccent : AppColors.greenAccent;
    final bgColor = isDark ? const Color(0xFF151D30) : const Color(0xFFF1F5F9);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpense
              ? AppColors.redAccent.withValues(alpha: 0.2)
              : AppColors.greenAccent.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com tipo e categoria
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isExpense
                  ? AppColors.redAccent.withValues(alpha: 0.08)
                  : AppColors.greenAccent.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isExpense ? Icons.arrow_circle_down_rounded : Icons.arrow_circle_up_rounded,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  isExpense ? l10n.expense : l10n.income,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(iconName),
                        size: 13,
                        color: isDark ? Colors.white70 : AppColors.darkSlate,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppColors.darkSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detalhes Principais (Valor e Descrição)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.formatSummaryValue(amount),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.darkSlate,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Botões de Confirmação Rápida
          if (!msg.isConfirmed && !msg.isCancelled) ...[
            const Divider(height: 1, thickness: 1),
            Row(
              children: [
                // Botão de Descartar
                Expanded(
                  child: TextButton(
                    onPressed: msg.isActionLoading
                        ? null
                        : () => _viewModel.cancelTransaction(msg),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.discard,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
                // Botão de Confirmar
                Expanded(
                  child: msg.isActionLoading
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: () async {
                            final success = await _viewModel.confirmTransaction(msg);
                            if (success && mounted) {
                              CustomToast.showSuccess(context, l10n.transactionSaved);
                            } else if (mounted) {
                              CustomToast.showError(context, 'Ocorreu um erro ao salvar lançamento.');
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(18),
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.confirm,
                            style: const TextStyle(
                              color: AppColors.accentOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ] else if (msg.isConfirmed) ...[
            // Badge de Confirmação Concluída
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.greenAccent.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.greenAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l10n.transactionLogged,
                    style: const TextStyle(
                      color: AppColors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (msg.isCancelled) ...[
            // Badge de Descartado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l10n.transactionDiscarded,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomInset = 90 + bottomPadding + 20;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, totalBottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.darkSlate,
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  hintText: l10n.typeMessage,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                    fontSize: 14.5,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _viewModel.isLoading ? null : _handleSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _viewModel.isLoading ? Colors.grey : AppColors.accentOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!_viewModel.isLoading)
                    BoxShadow(
                      color: AppColors.accentOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

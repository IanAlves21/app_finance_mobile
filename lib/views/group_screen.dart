import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodels/group_view_model.dart';
import '../services/service_locator.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_toast.dart';
import '../l10n/app_localizations.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late final GroupViewModel _viewModel;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _viewModel = locator<GroupViewModel>();
    _viewModel.loadGroupInfo();
  }

  void _copyToClipboard(String text, {String? successMessage}) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.showSuccess(context, successMessage ?? AppLocalizations.of(context)!.inviteCodeCopied);
  }

  void _shareInviteLink(String link) {
    final l10n = AppLocalizations.of(context)!;
    Share.share(
      l10n.shareInviteMsg(link),
      subject: l10n.shareInviteSubject,
    );
  }

  void _showInviteDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isActionLoading = true;
    });

    try {
      await _viewModel.generateInvite();
    } catch (_) {
      // Erros serão tratados através do viewModel.errorMessage abaixo
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }

    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      CustomToast.showError(context, '${l10n.googleSignInButton.startsWith('Entrar') ? 'Falha ao gerar convite' : 'Failed to generate invite'}: ${_viewModel.errorMessage}');
      return;
    }

    final inviteLink = 'financeapp://invite/${_viewModel.inviteCode}';

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            l10n.invitePartner,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.darkSlate,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.shareInvitePrompt,
                style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 14),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _copyToClipboard(inviteLink),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          inviteLink,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy_rounded, color: Colors.blue, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareInviteLink(inviteLink),
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                  label: Text(
                    l10n.shareInviteBtn,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.shareInviteOrCode,
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(_viewModel.inviteCode ?? '', successMessage: l10n.inviteOnlyCodeCopied),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.blue.withValues(alpha: 0.4) : Colors.blue.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          _viewModel.inviteCode ?? '',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 6,
                            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.copy_rounded,
                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_viewModel.inviteExpiresAt != null)
                Text(
                  l10n.expiresAtLabel(DateFormat('dd/MM/yyyy HH:mm').format(_viewModel.inviteExpiresAt!.toLocal())),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAcceptCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            l10n.acceptInvite,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.darkSlate,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.enterGroupPrompt,
                style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                ],
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.darkSlate,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: l10n.codePlaceholder,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                    letterSpacing: 4,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code = codeController.text.trim();
                    if (code.length != 6) {
                      CustomToast.showError(context, l10n.codeLengthError);
                      return;
                    }
                    Navigator.pop(context); // Fecha o diálogo de entrada de código

                    setState(() {
                      _isActionLoading = true;
                    });

                    bool success = false;
                    try {
                      await _viewModel.acceptInvite(code);
                      success = true;
                    } catch (e) {
                      if (mounted) {
                        CustomToast.showError(context, l10n.groupJoinError(e.toString()));
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isActionLoading = false;
                        });
                      }
                    }

                    if (success && mounted) {
                      CustomToast.showSuccess(context, l10n.groupJoinSuccess);
                      Navigator.pop(context, true); // Retorna sinalizando necessidade de refresh da Home
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: AppColors.accentOrange,
                  ),
                  child: Text(l10n.enter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _confirmLeaveGroup(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            l10n.leaveGroupTitle,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.darkSlate,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.leaveGroupConfirmMsg,
            style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 14),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context); // Fecha o diálogo de confirmação

                    setState(() {
                      _isActionLoading = true;
                    });

                    bool success = false;
                    try {
                      await _viewModel.leaveGroup();
                      success = true;
                    } catch (e) {
                      if (context.mounted) {
                        CustomToast.showError(context, l10n.leaveGroupError(e.toString()));
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() {
                          _isActionLoading = false;
                        });
                      }
                    }

                    if (success && context.mounted) {
                      CustomToast.showSuccess(context, l10n.leaveGroupSuccess);
                    }
                  },
                  child: Text(
                    l10n.confirm,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.darkSlate,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.darkSlate;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7A99);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final l10n = AppLocalizations.of(context)!;

    final SystemUiOverlayStyle overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.members.isEmpty) {
            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: Text(l10n.myFamilyGroup, style: const TextStyle(fontWeight: FontWeight.bold)),
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: textColor,
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                  statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
                ),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final showButtons = _viewModel.members.isNotEmpty && !_viewModel.isLoading;

          return Stack(
            children: [
              Scaffold(
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                appBar: AppBar(
                  title: Text(l10n.myFamilyGroup, style: const TextStyle(fontWeight: FontWeight.bold)),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  foregroundColor: textColor,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                ),
                body: _viewModel.isLoading && _viewModel.members.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Family Title Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentOrange.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.people_alt_rounded, color: AppColors.accentOrange, size: 28),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _viewModel.groupName ?? l10n.myFamilyGroup,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              l10n.groupSubtitle,
                                              style: TextStyle(color: subTextColor, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Members List Header
                            Text(
                              l10n.groupMembers,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Members List Cards
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _viewModel.members.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final member = _viewModel.members[index];
                                final String name = member['name'] as String? ?? l10n.unknownUser;
                                final String email = member['email'] as String? ?? '';
                                final String initials = name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: cardBgColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.blue.withValues(alpha: 0.15),
                                        child: Text(
                                          initials,
                                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              email,
                                              style: TextStyle(color: subTextColor, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                bottomNavigationBar: _viewModel.members.isNotEmpty && !_viewModel.isLoading
                    ? SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _showInviteDialog(context),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        backgroundColor: AppColors.accentOrange,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.invitePartner,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _showAcceptCodeDialog(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.vpn_key_rounded, color: textColor, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.acceptInvite,
                                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_viewModel.members.length > 1) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _confirmLeaveGroup(context),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          side: const BorderSide(color: Colors.redAccent),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.leaveGroup,
                                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
              if (_isActionLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

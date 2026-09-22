import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../main.dart'; // import global themeNotifier & localeNotifier
import '../services/session_manager.dart';
import '../services/secure_storage_manager.dart';
import '../services/service_locator.dart';
import '../repositories/transaction_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  bool _darkMode = themeNotifier.value == ThemeMode.dark ||
      (themeNotifier.value == ThemeMode.system &&
       ui.PlatformDispatcher.instance.platformBrightness == ui.Brightness.dark);
  bool _pushNotifications = true;
  bool _biometricAuth = false;
  bool _isExporting = false;

  bool get darkMode => _darkMode;
  bool get pushNotifications => _pushNotifications;
  bool get biometricAuth => _biometricAuth;
  bool get isExporting => _isExporting;

  SettingsViewModel({
    TransactionRepository? transactionRepository,
  }) : _transactionRepository = transactionRepository ?? locator<TransactionRepository>() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _biometricAuth = prefs.getBool('biometric_auth') ?? false;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  void toggleDarkMode(bool value) async {
    _darkMode = value;
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', value ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Erro ao persistir preferência de tema: $e');
    }
  }

  void togglePushNotifications(bool value) async {
    _pushNotifications = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications', value);
    } catch (_) {}
  }

  Future<bool> toggleBiometricAuth(bool value, {String? passwordConfirm}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value) {
        final localAuth = LocalAuthentication();
        final bool canAuthenticateWithBiometrics = await localAuth.canCheckBiometrics;
        final bool isDeviceSupported = await localAuth.isDeviceSupported();

        if (!canAuthenticateWithBiometrics || !isDeviceSupported) {
          return false; // Não suporta biometria
        }

        final bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Confirme sua biometria para habilitar o login rápido',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );

        if (!didAuthenticate) {
          return false;
        }

        // Se uma senha foi fornecida para salvar credenciais de login biometria
        if (passwordConfirm != null && passwordConfirm.isNotEmpty) {
          final currentUser = currentUserNotifier.value;
          if (currentUser != null) {
            await SecureStorageManager.write('biometric_email', currentUser.email);
            await SecureStorageManager.write('biometric_password', passwordConfirm);
          }
        }

        _biometricAuth = true;
        await prefs.setBool('biometric_auth', true);
      } else {
        _biometricAuth = false;
        await prefs.setBool('biometric_auth', false);
        await SecureStorageManager.delete('biometric_email');
        await SecureStorageManager.delete('biometric_password');
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao alternar biometria: $e');
      return false;
    }
  }

  /// Gera, salva localmente e abre o relatório PDF das transações do mês corrente
  Future<bool> exportCurrentMonthReport() async {
    _isExporting = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final String startDateStr = "${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-01";
      final String endDateStr = "${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";

      final Uint8List pdfBytes = await _transactionRepository.fetchReportPdf(
        startDate: startDateStr,
        endDate: endDateStr,
      );

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/Relatorio_Financeiro_${startDateStr}_$endDateStr.pdf';
      final file = File(path);
      await file.writeAsBytes(pdfBytes, flush: true);

      await OpenFilex.open(path);

      _isExporting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao exportar PDF na SettingsViewModel: $e');
      _isExporting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await SessionManager.logout();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finance_mobile/services/session_manager.dart';
import 'package:app_finance_mobile/services/secure_storage_manager.dart';
import 'package:app_finance_mobile/main.dart';
import 'package:app_finance_mobile/models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SecureStorageManager.useMock = true;
    SecureStorageManager.mockToken = 'sample_token';
  });

  test('SessionManager.logout clears session data but preserves app preferences', () async {
    SharedPreferences.setMockInitialValues({
      // Session & Cache data (should be cleared)
      'user_id': '123',
      'user_name': 'Test User',
      'user_email': 'test@example.com',
      'is_logged_in': true,
      'cached_transactions': '[{"id": 1}]',
      'chat_history': '[]',

      // App & User Preferences (should be preserved)
      'biometric_auth': true,
      'theme_mode': 'dark',
      'push_notifications': true,
      'language_code': 'pt',
    });

    currentUserNotifier.value = User(id: '123', name: 'Test User', email: 'test@example.com');
    isLoggedInNotifier.value = true;

    await SessionManager.logout();

    final prefs = await SharedPreferences.getInstance();

    // Verify session data was cleared
    expect(prefs.containsKey('user_id'), isFalse);
    expect(prefs.containsKey('user_name'), isFalse);
    expect(prefs.containsKey('user_email'), isFalse);
    expect(prefs.containsKey('is_logged_in'), isFalse);
    expect(prefs.containsKey('cached_transactions'), isFalse);
    expect(prefs.containsKey('chat_history'), isFalse);

    // Verify preferences were preserved
    expect(prefs.getBool('biometric_auth'), isTrue);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getBool('push_notifications'), isTrue);
    expect(prefs.getString('language_code'), 'pt');

    // Verify reactive notifiers
    expect(currentUserNotifier.value, isNull);
    expect(isLoggedInNotifier.value, isFalse);
    expect(await SecureStorageManager.readToken(), isNull);
  });
}

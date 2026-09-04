import 'package:flutter/foundation.dart';
import '../repositories/group_repository.dart';
import '../services/service_locator.dart';

class GroupViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository = locator<GroupRepository>();

  String? _groupName;
  List<dynamic> _members = [];
  String? _inviteCode;
  DateTime? _inviteExpiresAt;
  bool _isLoading = false;
  String? _errorMessage;

  String? get groupName => _groupName;
  List<dynamic> get members => _members;
  String? get inviteCode => _inviteCode;
  DateTime? get inviteExpiresAt => _inviteExpiresAt;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Busca informações sobre o grupo familiar atual e seus membros
  Future<void> loadGroupInfo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await _groupRepository.fetchGroupInfo();
      _groupName = info['name'] as String?;
      _members = info['members'] as List<dynamic>? ?? [];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gera um convite (código/token) para o grupo familiar atual
  Future<void> generateInvite() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final invite = await _groupRepository.createInvite();
      _inviteCode = invite['code'] as String?;
      if (invite['expiresAt'] != null) {
        _inviteExpiresAt = DateTime.parse(invite['expiresAt'] as String);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca os detalhes de um convite a partir de seu código curto
  Future<Map<String, dynamic>> loadInviteDetails(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _groupRepository.fetchInviteDetails(code);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aceita o convite e integra o grupo correspondente
  Future<void> acceptInvite(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _groupRepository.acceptInvite(code);
      await loadGroupInfo(); // Recarrega os membros locais após a mesclagem!
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sai do grupo familiar atual e volta para um grupo individual
  Future<void> leaveGroup() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _groupRepository.leaveGroup();
      await loadGroupInfo(); // Recarrega os membros locais após a saída!
    } catch (e) {
      _errorMessage = e.toString().replaceAll('HttpException: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

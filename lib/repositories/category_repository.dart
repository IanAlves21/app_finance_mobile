import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/secure_storage_manager.dart';

class CategoryRepository {
  final ApiService _apiService;

  CategoryRepository({required this._apiService});

  /// Busca as categorias do servidor com suporte a cache local e auto-sincronização
  Future<List<Category>> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();

    // Tenta sincronizar categorias pendentes offline primeiro antes de carregar do servidor!
    try {
      await syncPendingCategories();
    } catch (syncError) {
      debugPrint('Erro ao sincronizar categorias antes de fetch: $syncError');
    }

    final String? token = await SecureStorageManager.readToken();

    if (token != null && ApiService.isTokenExpired(token)) {
      await _apiService.logout();
      throw const HttpException('Unauthorized');
    }

    try {
      final response = await _apiService
          .get('/transactions/categories')
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Se ainda houver categorias offline pendentes que falharam no sync, mescla-as no resultado
        try {
          final String? pendingData = prefs.getString('pending_categories');
          if (pendingData != null && pendingData.isNotEmpty) {
            final List<dynamic> pendingList = json.decode(pendingData);
            for (int i = 0; i < pendingList.length; i++) {
              final catMap = pendingList[i];
              data.add({
                'id': 'offline_cat_fetch_$i',
                'name': catMap['name'],
                'type': catMap['type'],
                'icon': catMap['icon'],
                'color': catMap['color'],
                'familyId': 'offline_family',
              });
            }
          }
        } catch (_) {}

        try {
          await prefs.setString('cached_categories', json.encode(data));
        } catch (cacheError) {
          debugPrint('Erro ao salvar cache de categorias: $cacheError');
        }
        return data.map((json) => Category.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw HttpException('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint('CategoryRepository error, carregando categorias do cache local: $e');

      try {
        final String? cachedData = prefs.getString('cached_categories');
        if (cachedData != null) {
          final List<dynamic> data = json.decode(cachedData);
          return data.map((json) => Category.fromJson(json)).toList();
        }
      } catch (cacheError) {
        debugPrint('Falha ao ler categorias do cache local: $cacheError');
      }

      return [];
    }
  }

  /// Cria uma categoria (online ou enfileira offline se estiver sem rede)
  Future<Category> createCategory({
    required String name,
    required String type, // 'INCOME' ou 'EXPENSE'
    required String icon,
    required String color,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _apiService
          .post(
            '/transactions/categories',
            {
              'name': name,
              'type': type,
              'icon': icon,
              'color': color,
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Category newCat = Category.fromJson(data);

        // Atualiza o cache local de categorias
        try {
          final String? cachedData = prefs.getString('cached_categories');
          final List<dynamic> currentCats = cachedData != null ? json.decode(cachedData) : [];
          currentCats.add(data);
          await prefs.setString('cached_categories', json.encode(currentCats));
        } catch (_) {}

        return newCat;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw const HttpException('Falha ao criar categoria');
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint('CategoryRepository: Erro durante criação de categoria, enfileirando offline: $e');

      final String localId = 'offline_cat_${DateTime.now().millisecondsSinceEpoch}';
      final localMockCat = {
        'id': localId,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
        'familyId': 'offline_family', // Indica que é customizada localmente
      };

      final pendingCat = {
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
      };

      try {
        // 1. Adiciona ao final da fila de pendentes
        final List<dynamic> pendingList = [];
        final String? existingPending = prefs.getString('pending_categories');
        if (existingPending != null && existingPending.isNotEmpty) {
          pendingList.addAll(json.decode(existingPending));
        }
        pendingList.add(pendingCat);
        await prefs.setString('pending_categories', json.encode(pendingList));

        // 2. Adiciona imediatamente ao cache de categorias para exibição instantânea
        final String? cachedData = prefs.getString('cached_categories');
        final List<dynamic> currentCats = cachedData != null ? json.decode(cachedData) : [];
        currentCats.add(localMockCat);
        await prefs.setString('cached_categories', json.encode(currentCats));

        return Category.fromJson(localMockCat);
      } catch (cacheError) {
        debugPrint('Erro ao enfileirar categoria offline: $cacheError');
        rethrow;
      }
    }
  }

  /// Atualiza uma categoria no servidor (ou enfileira offline com atualização imediata de cache se sem rede)
  Future<Category> updateCategory({
    required String id,
    String? name,
    String? type,
    String? icon,
    String? color,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _apiService
          .patch(
            '/transactions/categories/$id',
            {
              'name': ?name,
              'type': ?type,
              'icon': ?icon,
              'color': ?color,
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Category updated = Category.fromJson(data);

        // Atualiza o cache local
        try {
          final String? cachedData = prefs.getString('cached_categories');
          if (cachedData != null) {
            final List<dynamic> currentCats = json.decode(cachedData);
            final int index = currentCats.indexWhere((cat) => cat['id'] == id);
            if (index != -1) {
              currentCats[index] = data;
              await prefs.setString('cached_categories', json.encode(currentCats));
            }
          }
        } catch (_) {}

        return updated;
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        throw const HttpException('Falha ao atualizar categoria');
      }
    } catch (e) {
      if (e is HttpException && e.message == 'Unauthorized') {
        rethrow;
      }
      debugPrint('CategoryRepository: Erro ao atualizar categoria, enfileirando offline: $e');

      // 1. Cria uma representação do modelo atualizado localmente lendo o cache atual
      String currentName = name ?? '';
      String currentType = type ?? 'EXPENSE';
      String currentIcon = icon ?? 'category';
      String currentColor = color ?? '#1A2D5A';
      String? currentFamilyId = 'offline_family';

      try {
        final String? cachedData = prefs.getString('cached_categories');
        if (cachedData != null) {
          final List<dynamic> currentCats = json.decode(cachedData);
          final int index = currentCats.indexWhere((cat) => cat['id'] == id);
          if (index != -1) {
            final existingCat = currentCats[index];
            currentName = name ?? existingCat['name'] ?? '';
            currentType = type ?? existingCat['type'] ?? 'EXPENSE';
            currentIcon = icon ?? existingCat['icon'] ?? 'category';
            currentColor = color ?? existingCat['color'] ?? '#1A2D5A';
            currentFamilyId = existingCat['familyId'];

            // Atualiza imediatamente o cache de categorias locais
            existingCat['name'] = currentName;
            existingCat['type'] = currentType;
            existingCat['icon'] = currentIcon;
            existingCat['color'] = currentColor;
            await prefs.setString('cached_categories', json.encode(currentCats));
          }
        }
      } catch (_) {}

      final localMockCat = {
        'id': id,
        'name': currentName,
        'type': currentType,
        'icon': currentIcon,
        'color': currentColor,
        'familyId': currentFamilyId,
      };

      final pendingUpdate = {
        'id': id,
        'name': name,
        'type': type,
        'icon': icon,
        'color': color,
      };

      try {
        // 2. Adiciona ao final da fila de atualizações pendentes
        final List<dynamic> pendingUpdatesList = [];
        final String? existingPending = prefs.getString('pending_category_updates');
        if (existingPending != null && existingPending.isNotEmpty) {
          pendingUpdatesList.addAll(json.decode(existingPending));
        }
        pendingUpdatesList.add(pendingUpdate);
        await prefs.setString('pending_category_updates', json.encode(pendingUpdatesList));

        return Category.fromJson(localMockCat);
      } catch (cacheError) {
        debugPrint('Erro ao enfileirar atualização offline de categoria: $cacheError');
        rethrow;
      }
    }
  }

  /// Exclui uma categoria do servidor e remove localmente
  Future<void> deleteCategory(String id) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _apiService
          .delete('/transactions/categories/$id')
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove do cache local
        try {
          final String? cachedData = prefs.getString('cached_categories');
          if (cachedData != null) {
            final List<dynamic> currentCats = json.decode(cachedData);
            currentCats.removeWhere((cat) => cat['id'] == id);
            await prefs.setString('cached_categories', json.encode(currentCats));
          }
        } catch (_) {}
      } else if (response.statusCode == 401) {
        await _apiService.logout();
        throw const HttpException('Unauthorized');
      } else {
        String errMsg = 'Falha ao excluir categoria';
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data.containsKey('message')) {
            errMsg = data['message'].toString();
          }
        } catch (_) {}
        throw HttpException(errMsg);
      }
    } catch (e) {
      if (e is HttpException) {
        rethrow;
      }
      throw HttpException('Erro ao excluir categoria: $e');
    }
  }

  /// Sincroniza atualizações de categorias feitas offline
  Future<void> syncPendingCategoryUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? pendingData = prefs.getString('pending_category_updates');
      if (pendingData == null || pendingData.isEmpty) return;

      final List<dynamic> pendingList = json.decode(pendingData);
      if (pendingList.isEmpty) return;

      final String? token = await SecureStorageManager.readToken();
      if (token != null && ApiService.isTokenExpired(token)) {
        return;
      }

      final List<dynamic> remainingPending = [];

      debugPrint('CategoryRepository: Iniciando sincronização de ${pendingList.length} atualizações de categorias offline...');

      for (final updateMap in pendingList) {
        try {
          final String catId = updateMap['id'];
          
          // Se o ID for provisório offline, não dá para atualizar no servidor diretamente!
          // Mas ele já será criado com os dados mais recentes na fila de criação.
          if (catId.startsWith('offline_cat_')) {
            continue;
          }

          final response = await _apiService
              .patch('/transactions/categories/$catId', {
                if (updateMap['name'] != null) 'name': updateMap['name'],
                if (updateMap['type'] != null) 'type': updateMap['type'],
                if (updateMap['icon'] != null) 'icon': updateMap['icon'],
                if (updateMap['color'] != null) 'color': updateMap['color'],
              })
              .timeout(const Duration(seconds: 5));

          if (response.statusCode != 200) {
            if (response.statusCode == 401) {
              await _apiService.logout();
              throw const HttpException('Unauthorized');
            }
            remainingPending.add(updateMap);
          }
        } catch (e) {
          remainingPending.addAll(pendingList.sublist(pendingList.indexOf(updateMap)));
          debugPrint('CategoryRepository: Pausando sincronização de atualizações devido a erro de rede: $e');
          break;
        }
      }

      if (remainingPending.isEmpty) {
        await prefs.remove('pending_category_updates');
        debugPrint('CategoryRepository: Sincronização offline de atualizações de categorias concluída!');
      } else {
        await prefs.setString('pending_category_updates', json.encode(remainingPending));
        debugPrint('CategoryRepository: Sincronização de atualizações incompleta. ${remainingPending.length} restantes na fila.');
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar atualizações de categorias offline: $e');
    }
  }

  /// Sincroniza categorias pendentes criadas offline
  Future<void> syncPendingCategories() async {
    try {
      // Primeiro, sincroniza as atualizações pendentes de categorias existentes!
      await syncPendingCategoryUpdates();

      final prefs = await SharedPreferences.getInstance();
      final String? pendingData = prefs.getString('pending_categories');
      if (pendingData == null || pendingData.isEmpty) return;

      final List<dynamic> pendingList = json.decode(pendingData);
      if (pendingList.isEmpty) return;

      final String? token = await SecureStorageManager.readToken();
      if (token != null && ApiService.isTokenExpired(token)) {
        return;
      }

      final List<dynamic> remainingPending = [];

      debugPrint('CategoryRepository: Iniciando sincronização de ${pendingList.length} categorias offline...');

      for (final catMap in pendingList) {
        try {
          final response = await _apiService
              .post('/transactions/categories', {
                'name': catMap['name'],
                'type': catMap['type'],
                'icon': catMap['icon'],
                'color': catMap['color'],
              })
              .timeout(const Duration(seconds: 5));

          if (response.statusCode != 200 && response.statusCode != 201) {
            if (response.statusCode == 401) {
              await _apiService.logout();
              throw const HttpException('Unauthorized');
            }
            remainingPending.add(catMap);
          }
        } catch (e) {
          remainingPending.addAll(pendingList.sublist(pendingList.indexOf(catMap)));
          debugPrint('CategoryRepository: Pausando sincronização de categorias devido a erro de rede: $e');
          break;
        }
      }

      if (remainingPending.isEmpty) {
        await prefs.remove('pending_categories');
        debugPrint('CategoryRepository: Sincronização offline de categorias concluída!');
      } else {
        await prefs.setString('pending_categories', json.encode(remainingPending));
        debugPrint('CategoryRepository: Sincronização de categorias incompleta. ${remainingPending.length} restantes na fila.');
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar categorias offline: $e');
    }
  }
}

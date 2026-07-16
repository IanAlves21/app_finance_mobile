import 'package:get_it/get_it.dart';
import 'api_service.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/category_repository.dart';

final GetIt locator = GetIt.instance;

/// Inicializa o contêiner de Injeção de Dependências global do aplicativo
void setupLocator() {
  // Registra o ApiService como Singleton Preguiçoso (só é criado ao ser lido pela primeira vez)
  locator.registerLazySingleton<ApiService>(() => ApiService());

  // Registra os Repositórios de Regras de Negócio e Cache, injetando o ApiService neles
  locator.registerLazySingleton<TransactionRepository>(
    () => TransactionRepository(apiService: locator<ApiService>()),
  );
  locator.registerLazySingleton<CategoryRepository>(
    () => CategoryRepository(apiService: locator<ApiService>()),
  );
}

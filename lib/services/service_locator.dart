import 'package:get_it/get_it.dart';
import 'api_service.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/budget_repository.dart';
import '../viewmodels/add_transaction_view_model.dart';
import '../viewmodels/analytics_view_model.dart';
import '../viewmodels/category_list_view_model.dart';
import '../viewmodels/home_view_model.dart';
import '../viewmodels/login_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../viewmodels/transaction_history_view_model.dart';
import '../viewmodels/wallets_view_model.dart';

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
  locator.registerLazySingleton<BudgetRepository>(
    () => BudgetRepository(apiService: locator<ApiService>()),
  );

  // Registra as ViewModels como Fábricas Transitórias (Instâncias novas a cada requisição)
  locator.registerFactory<AddTransactionViewModel>(() => AddTransactionViewModel());
  locator.registerFactory<AnalyticsViewModel>(() => AnalyticsViewModel());
  locator.registerFactory<CategoryListViewModel>(() => CategoryListViewModel());
  locator.registerFactory<HomeViewModel>(() => HomeViewModel());
  locator.registerFactory<LoginViewModel>(() => LoginViewModel());
  locator.registerFactory<SettingsViewModel>(() => SettingsViewModel());
  locator.registerFactory<TransactionHistoryViewModel>(() => TransactionHistoryViewModel());
  locator.registerFactory<WalletsViewModel>(() => WalletsViewModel());
}

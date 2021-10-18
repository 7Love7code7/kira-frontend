import 'package:get_it/get_it.dart';
import 'package:kira_auth/services/export.dart';

final getIt = GetIt.instance;

void setupGetIt() {
  getIt.registerLazySingleton<AccountService>(() => AccountService());
  getIt.registerLazySingleton<ProposalService>(() => ProposalService());
  getIt.registerLazySingleton<QueryService>(() => QueryService());
  getIt.registerLazySingleton<RPCMethodsService>(() => RPCMethodsService());
  getIt.registerLazySingleton<TokenService>(() => TokenService());
  getIt.registerLazySingleton<TransactionService>(() => TransactionService());
  getIt.registerLazySingleton<NetworkService>(() => NetworkService());
  getIt.registerLazySingleton<StatusService>(() => StatusService());
  getIt.registerLazySingleton<StorageService>(() => SharedPreferencesStorage());
  getIt.registerLazySingleton<IdentityRegistrarService>(() => IdentityRegistrarService());
}

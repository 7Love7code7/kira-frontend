import 'package:kira_auth/models/export.dart';

enum ModelType { BLOCK, TRANSACTION, PROPOSAL }

abstract class StorageService {
  Future setAccountData(String info);
  Future<List<Account>> getAccountData();
  Future setCurrentAccount(String account);
  Future<Account> getCurrentAccount();
  Future removeCachedAccount();
  Future setFeeToken(String token);
  Future<Token> getFeeToken();
  Future removeFeeToken();
  Future<bool> setPassword(String password);
  Future<bool> removePassword();
  Future<String> getPassword();
  Future<bool> checkPasswordExists();
  Future setFeeAmount(int feeAmount);
  Future<int> getFeeAmount();
  Future setExpireTime(Duration maxAge);
  Future<bool> removeExpireTime();
  Future<bool> checkExpireTime();
  Future<int> getExpireTime();
  Future<String> getExplorerAddress();
  Future setExplorerAddress(String explorerAddress);
  Future<String> getInterxRPCUrl();
  Future setInterxRPCUrl(String interxRpcUrl);
  Future setTopBarStatus(bool display);
  Future<bool> getTopBarStatus();
  Future setLoginStatus(bool isLoggedIn);
  Future<bool> getLoginStatus();
  Future setLastFetchedTime(String key);
  Future setTopbarIndex(int index);
  Future<int> getTopbarIndex();
  Future setLastSearchedAccount(String account);
  Future<String> getLastSearchedAccount();
  Future setTabIndex(int tabIndex);
  Future<int> getTabIndex();
  Future<bool> checkPasswordExpired();
  Future<bool> checkModelExists(ModelType type, String id);
  Future storeModels(ModelType type, String id, String data);
  Future<Map> getModel(ModelType type, String id);
  Future<List<BlockTransaction>> getTransactionsForHeight(int height);
  Future setLiveRpcUrl(String liveRpcUrl, String origin);
  Future<List<String>> getLiveRpcUrl();
  Future setNodeStatusData(String _nodeStatus);
  Future<dynamic> getNodeStatusData(String _type);
  Future setNetworkHealth(bool _isNetworkHealthy);
  Future<bool> getNetworkHealth();
  Future setTokenBalance(String address, String _balanceData);
  Future<List<Token>> getTokenBalance(String address);
  Future setTransactions(String address, String _txData);
  Future<List<Transaction>> getTransactions(String address);
  Future setFaucetTokens(String _faucetTokenData);
  Future<List<String>> getFaucetTokens();
}

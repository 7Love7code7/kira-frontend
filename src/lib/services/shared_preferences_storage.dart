import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kira_auth/models/export.dart';
import 'storage_service.dart';

class SharedPreferencesStorage extends StorageService {
  static const String TS_PREFIX = 'spc_ts_';

  @override
  Future setAccountData(String info) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('ACCOUNTS');

    String accounts = cachedData == null ? "---" : cachedData;
    if (accounts.contains(info) != true) {
      accounts += info;
      accounts += "---";
      prefs.setString('ACCOUNTS', accounts);
      setCurrentAccount(info);
    }
  }

  @override
  Future setCurrentAccount(String account) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('CURRENT_ACCOUNT', account);
  }

  @override
  Future<String> getCurrentAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('CURRENT_ACCOUNT');
  }

  @override
  Future removeCachedAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('ACCOUNTS');
  }

  @override
  Future setFeeToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('FEE_TOKEN', token);
  }

  @override
  Future<String> getFeeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('FEE_TOKEN');
  }

  @override
  Future removeFeeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('FEE_TOKEN');
  }

  @override
  Future<bool> setPassword(String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await setLastFetchedTime('PASSWORD');

    bool isExpiredTimeExists = await checkExpireTime();
    int expireTime = await getExpireTime();

    if (isExpiredTimeExists == false || expireTime == 0) {
      setExpireTime(Duration(minutes: 60));
    }

    prefs.setString('PASSWORD', password);
    return true;
  }

  @override
  Future<bool> removePassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('PASSWORD');
    return true;
  }

  @override
  Future<String> getPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('PASSWORD');
  }

  @override
  Future<bool> checkPasswordExists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('PASSWORD');
  }

  @override
  Future setFeeAmount(int feeAmount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('FEE_AMOUNT', feeAmount);
  }

  @override
  Future setExpireTime(Duration maxAge) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('EXPIRE_TIME', maxAge.inMilliseconds);
  }

  @override
  Future<bool> removeExpireTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('EXPIRE_TIME');
    return true;
  }

  @override
  Future<bool> checkExpireTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('EXPIRE_TIME');
  }

  @override
  Future<int> getExpireTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('EXPIRE_TIME');
  }

  @override
  Future<String> getExplorerAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('EXPLORER_ADDRESS');
  }

  @override
  Future setExplorerAddress(String explorerAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('EXPLORER_ADDRESS', explorerAddress);
  }

  @override
  Future<String> getInterxRPCUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('INTERX_RPC');
  }

  @override
  Future setInterxRPCUrl(String interxRpcUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('INTERX_RPC', interxRpcUrl);
  }

  @override
  Future setTopBarStatus(bool display) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('TOP_BAR_STATUS', display);
  }

  @override
  Future<bool> getTopBarStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('TOP_BAR_STATUS');
  }

  @override
  Future setLoginStatus(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('LOGGED_IN', isLoggedIn);
  }

  @override
  Future<bool> getLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('LOGGED_IN') ?? false;
  }

  @override
  Future setLastFetchedTime(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int ts = DateTime.now().millisecondsSinceEpoch;
    prefs.setInt(getTimestampKey(key), ts);
  }

  String getTimestampKey(String forKey) {
    return TS_PREFIX + forKey;
  }

  @override
  Future setTopbarIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('TOP_BAR_INDEX', index);
  }

  @override
  Future<int> getTopbarIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('TOP_BAR_INDEX') ?? 0;
  }

  @override
  Future setLastSearchedAccount(String account) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('LAST_SEARCHED_ACCOUNT', account);
  }

  @override
  Future<String> getLastSearchedAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('LAST_SEARCHED_ACCOUNT') ?? "";
  }

  @override
  Future setTabIndex(int tabIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('TAB_INDEX', tabIndex);
  }

  @override
  Future<int> getTabIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('TAB_INDEX') ?? 0;
  }

  @override
  Future<bool> checkPasswordExpired() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool passwordExists = await checkPasswordExists();
    if (passwordExists == false) return true;

    // Get last fetched Time
    int ts = prefs.getInt(getTimestampKey('PASSWORD'));
    if (ts == null) return true;

    int expireTime = prefs.getInt('EXPIRE_TIME');
    int diff = DateTime.now().millisecondsSinceEpoch - ts;

    if (diff > expireTime) {
      removePassword();
      return true;
    }

    return false;
  }

  // ignore: missing_return
  String getKeyFromType(ModelType type) {
    switch (type) {
      case ModelType.BLOCK:
        return 'block';
      case ModelType.TRANSACTION:
        return 'tx_for_block';
      case ModelType.PROPOSAL:
        return 'proposal';
    }
  }

  @override
  Future<bool> checkModelExists(ModelType type, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('${getKeyFromType(type)}_$id');
  }

  @override
  Future storeModels(ModelType type, String id, String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('${getKeyFromType(type)}_$id', data);
  }

  @override
  Future<Map> getModel(ModelType type, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var dataStr = prefs.getString('${getKeyFromType(type)}_$id');
    try {
      return jsonDecode(dataStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BlockTransaction>> getTransactionsForHeight(int height) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var txStrings = prefs.getString('tx_for_block_$height');
    try {
      return (jsonDecode(txStrings) as List<dynamic>)
          .map((e) => BlockTransaction.fromJson(jsonDecode(e.toString()) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List.empty();
    }
  }

  // Caching API responses
  @override
  Future setLiveRpcUrl(String liveRpcUrl, String origin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('LIVE_RPC_URL', liveRpcUrl + "---" + origin);
  }

  @override
  Future<List<String>> getLiveRpcUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String rpcData = prefs.getString('LIVE_RPC_URL');
    if (rpcData == null || rpcData.isEmpty) {
      return ["", ""];
    }
    return rpcData.split('---');
  }

  @override
  Future setNodeStatusData(String _nodeStatus) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('NODE_STATUS', _nodeStatus);
  }

  @override
  Future<dynamic> getNodeStatusData(String _type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String nodeStatus = prefs.getString('NODE_STATUS');
    if (nodeStatus == null || nodeStatus == "") return null;
    var statusData = json.decode(nodeStatus);

    if (_type == "NODE_INFO") {
      return NodeInfo.fromJson(statusData['node_info']);
    }
    if (_type == "SYNC_INFO") {
      return SyncInfo.fromJson(statusData['sync_info']);
    }
    if (_type == "VALIDATOR_INFO") {
      return ValidatorInfo.fromJson(statusData['validator_info']);
    }
  }

  @override
  Future setNetworkHealth(bool _isNetworkHealthy) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('NETWORK_HEALTH', _isNetworkHealthy);
  }

  @override
  Future<bool> getNetworkHealth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('NETWORK_HEALTH');
  }
}

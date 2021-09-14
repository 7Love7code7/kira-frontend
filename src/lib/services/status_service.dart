// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/config.dart';
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class StatusService {
  NodeInfo nodeInfo;
  SyncInfo syncInfo;
  ValidatorInfo validatorInfo;
  bool isNetworkHealthy = true;
  String interxPubKey;
  String rpcUrl = "";

  final _storageService = getIt<StorageService>();

  Future<void> initialize() async {
    var networkHealth = await _storageService.getNetworkHealth();
    isNetworkHealthy = (networkHealth == null) ? false : networkHealth;
    nodeInfo = await _storageService.getNodeStatusData("NODE_INFO");
    syncInfo = await _storageService.getNodeStatusData("SYNC_INFO");
    validatorInfo = await _storageService.getNodeStatusData("VALIDATOR_INFO");
  }

  void disconnect() {
    nodeInfo = null;
    syncInfo = null;
    validatorInfo = null;
    rpcUrl = "";
    isNetworkHealthy = false;
  }

  Future<bool> getNodeStatus() async {
    var apiUrl = await _storageService.getLiveRpcUrl();

    if (apiUrl[0].isEmpty) {
      apiUrl = await loadInterxURL();
    }

    var config = await loadConfig();
    var response;

    rpcUrl = getIPOnly(apiUrl[0]);

    response = await http.get(apiUrl[0] + "/api/kira/status",
        headers: {'Access-Control-Allow-Origin': apiUrl[1]}).timeout(Duration(seconds: 3));

    if (response.body.contains('node_info') == false && config[0] == true) {
      rpcUrl = getIPOnly(config[1]);

      response = await http.get(config[1] + "/api/kira/status",
          headers: {'Access-Control-Allow-Origin': apiUrl[1]}).timeout(Duration(seconds: 3));

      if (response.body.contains('node_info') == false) {
        isNetworkHealthy = false;
        _storageService.setNetworkHealth(false);
        return false;
      }
    }

    var bodyData;
    try {
      bodyData = json.decode(response.body);
    } catch (e) {
      isNetworkHealthy = false;
      _storageService.setNetworkHealth(false);
      return false;
    }

    nodeInfo = NodeInfo.fromJson(bodyData['node_info']);
    syncInfo = SyncInfo.fromJson(bodyData['sync_info']);
    validatorInfo = ValidatorInfo.fromJson(bodyData['validator_info']);

    _storageService.setNodeStatusData(response.body);
    _storageService.setNetworkHealth(true);
    isNetworkHealthy = true;

    response = await http.get(apiUrl[0] + '/api/status', headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    if (response.body.contains('interx_info') == false && config[0] == true) {
      response = await http.get(config[1] + "/api/status", headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      if (response.body.contains('interx_info') == false) {
        return false;
      }
    }

    bodyData = json.decode(response.body);
    interxPubKey = bodyData['interx_info']['pub_key']['value'];

    return true;
  }

  Future<String> checkNodeStatus(String _apiUrl) async {
    String apiUrl = _apiUrl.replaceAll('http://', '');
    apiUrl = apiUrl.replaceAll('https://', '');
    apiUrl = apiUrl.trim();

    String origin = html.window.location.host + html.window.location.pathname;
    origin = origin.replaceAll('/', '');

    try {
      var response = await http.get(apiUrl + "/api/kira/status",
          headers: {'Access-Control-Allow-Origin': origin}).timeout(Duration(seconds: 3));

      if (response.body.contains('node_info') == true) {
        _storageService.setLiveRpcUrl(apiUrl, origin);
        return apiUrl;
      }
    } catch (e) {
      print(e);
    }

    try {
      var response = await http.get('https://' + apiUrl + "/api/kira/status",
          headers: {'Access-Control-Allow-Origin': origin}).timeout(Duration(seconds: 3));

      if (response.body.contains('node_info') == true) {
        _storageService.setLiveRpcUrl('https://' + apiUrl, origin);
        return 'https://' + apiUrl;
      }
    } catch (e) {
      print(e);
    }

    try {
      var response = await http.get('https://cors-anywhere.kira.network/http://' + apiUrl + "/api/kira/status",
          headers: {'Access-Control-Allow-Origin': origin}).timeout(Duration(seconds: 3));

      if (response.body.contains('node_info') == true) {
        _storageService.setLiveRpcUrl('https://cors-anywhere.kira.network/http://' + apiUrl, origin);
        return 'https://cors-anywhere.kira.network/http://' + apiUrl;
      }
    } catch (e) {
      print(e);
    }

    try {
      var response = await http.get('https://cors-anywhere.kira.network/http://' + apiUrl + ":11000/api/kira/status",
          headers: {'Access-Control-Allow-Origin': origin}).timeout(Duration(seconds: 3));

      if (response.body.contains('node_info') == true) {
        _storageService.setLiveRpcUrl('https://cors-anywhere.kira.network/http://' + apiUrl + ':11000', origin);
        return 'https://cors-anywhere.kira.network/http://' + apiUrl + ':11000';
      }
    } catch (e) {
      print(e);
    }

    return "invalid";
  }
}

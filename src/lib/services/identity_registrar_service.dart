import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class IdentityRegistrarService {
  final _storageService = getIt<StorageService>();

  List<IdentityRegistrar> iRecords = [];
  List<IdentityRegistrar> iRecordVerifyRequests = [];

  void initialize() async {
    iRecords = await _storageService.getAllIdentityRegistrarRecords();
  }

  Future<IdentityRegistrar> queryIdentityRecord(String id) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRegistrar identityRegistrar = IdentityRegistrar();

    try {
      var response = await http
          .get(apiUrl[0] + "/api/kira/gov/identity_record/" + id, headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);

      identityRegistrar.address = body['record']['address'];
      identityRegistrar.date = body['record']['date'];
      identityRegistrar.id = body['record']['id'];
      identityRegistrar.key = body['record']['key'];
      identityRegistrar.value = body['record']['value'];
    } catch (e) {
      print(e);
      return null;
    }

    return identityRegistrar;
  }

  Future<IdentityRegistrar> queryIdentityRecordByAddress(String creater) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRegistrar identityRegistrar = IdentityRegistrar();

    try {
      var response = await http.get(apiUrl[0] + "/api/kira/gov/identity_records/" + creater,
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);

      identityRegistrar.address = body['record']['address'];
      identityRegistrar.date = body['record']['date'];
      identityRegistrar.id = body['record']['id'];
      identityRegistrar.key = body['record']['key'];
      identityRegistrar.value = body['record']['value'];
    } catch (e) {
      print(e);
      return null;
    }

    return identityRegistrar;
  }

  Future<IdentityRegistrar> queryIdentityRecordVerifyRequest(String requestId) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRegistrar identityRegistrar = IdentityRegistrar();

    try {
      var response = await http.get(apiUrl[0] + "/api/kira/gov/identity_verify_record/" + requestId,
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);
      // TODO: Confirm the format of verify request api response

    } catch (e) {
      print(e);
      return null;
    }

    return identityRegistrar;
  }

  Future<IdentityRegistrar> queryIdentityRecordVerifyRequestsByRequester(String requester) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRegistrar identityRegistrar = IdentityRegistrar();

    try {
      var response = await http.get(apiUrl[0] + "/api/kira/gov/identity_verify_requests_by_requester/" + requester,
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);
      // TODO: Confirm the format of verify requests by requester api response

    } catch (e) {
      print(e);
      return null;
    }

    return identityRegistrar;
  }

  Future<IdentityRegistrar> queryIdentityRecordVerifyRequestsByApprover(String approver) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRegistrar identityRegistrar = IdentityRegistrar();

    try {
      var response = await http.get(apiUrl[0] + "/api/kira/gov/identity_verify_requests_by_approver/" + approver,
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);
      // TODO: Confirm the format of verify requests by requester api response

    } catch (e) {
      print(e);
      return null;
    }

    return identityRegistrar;
  }

  Future queryAllIdentityRegistrarRecords() async {
    var apiUrl = await _storageService.getLiveRpcUrl();

    try {
      var response = await http
          .get(apiUrl[0] + "/api/kira/gov/all_identity_records", headers: {'Access-Control-Allow-Origin': apiUrl[1]});

      var body = jsonDecode(response.body);

      for (var record in body['records']) {
        IdentityRegistrar identityRegistrar = IdentityRegistrar();
        identityRegistrar.address = record['address'];
        identityRegistrar.date = record['date'];
        identityRegistrar.id = record['id'];
        identityRegistrar.key = record['key'];
        identityRegistrar.value = record['value'];
        iRecords.add(identityRegistrar);
      }

      _storageService.setAllIdentityRegistrarRecords(jsonEncode(iRecords));
    } catch (e) {
      print(e);
      return;
    }
  }

  // TODO: Incompleted function
  Future queryAllIdentityRecordVerifyRequests() async {
    var apiUrl = await _storageService.getLiveRpcUrl();

    try {
      var response = await http.get(apiUrl[0] + "/api/kira/gov/all_identity_verify_requests",
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});

      var body = jsonDecode(response.body);

      for (var record in body['records']) {
        IdentityRegistrar identityRegistrar = IdentityRegistrar();
        identityRegistrar.address = record['address'];
        identityRegistrar.date = record['date'];
        identityRegistrar.id = record['id'];
        identityRegistrar.key = record['key'];
        identityRegistrar.value = record['value'];
        iRecords.add(identityRegistrar);
      }

      // _storageService.setAllIdentityRegistrarRecords(jsonEncode(iRecords));
    } catch (e) {
      print(e);
      return;
    }
  }
}

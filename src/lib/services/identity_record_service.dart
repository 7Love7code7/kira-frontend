import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class IdentityRecordService {
  final _storageService = getIt<StorageService>();

  List<IdentityRecord> iRecords = [];
  List<IdentityRecord> iRecordVerifyRequests = [];

  void initialize() async {
    iRecords = await _storageService.getAllIdentityRecords();
  }

  Future<IdentityRecord> queryIdentityRecord(String id) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRecord identityRecord = IdentityRecord();

    try {
      var response = await http
          .get(apiUrl[0] + "/api/kira/gov/identity_record/" + id, headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);

      identityRecord.address = body['record']['address'];
      identityRecord.date = body['record']['date'];
      identityRecord.id = body['record']['id'];
      identityRecord.key = body['record']['key'];
      identityRecord.value = body['record']['value'];
    } catch (e) {
      print(e);
      return null;
    }

    return identityRecord;
  }

  Future<IdentityRecord> queryIdentityRecordByAddress(String creater) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRecord identityRecord = IdentityRecord();

    try {
      var response = await http.get(apiUrl[0] + "/api/kira/gov/identity_records/" + creater,
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);

      identityRecord.address = body['record']['address'];
      identityRecord.date = body['record']['date'];
      identityRecord.id = body['record']['id'];
      identityRecord.key = body['record']['key'];
      identityRecord.value = body['record']['value'];
    } catch (e) {
      print(e);
      return null;
    }

    return identityRecord;
  }

  Future<IdentityRecord> queryIdentityRecordVerifyRequest(String requestId) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRecord identityRecord = IdentityRecord();

    try {
      var response = await http.get(apiUrl[0] + "/api/kira/gov/identity_verify_record/" + requestId,
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);
      // TODO: Confirm the format of verify request api response

    } catch (e) {
      print(e);
      return null;
    }

    return identityRecord;
  }

  Future<IdentityRecord> queryIdentityRecordVerifyRequestsByRequester(String requester) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRecord identityRecord = IdentityRecord();

    try {
      var response = await http.get(apiUrl[0] + "/api/kira/gov/identity_verify_requests_by_requester/" + requester,
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);
      // TODO: Confirm the format of verify requests by requester api response

    } catch (e) {
      print(e);
      return null;
    }

    return identityRecord;
  }

  Future<IdentityRecord> queryIdentityRecordVerifyRequestsByApprover(String approver) async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    IdentityRecord identityRecord = IdentityRecord();

    try {
      var response = await http.get(apiUrl[0] + "/api/kira/gov/identity_verify_requests_by_approver/" + approver,
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});
      var body = jsonDecode(response.body);
      // TODO: Confirm the format of verify requests by requester api response

    } catch (e) {
      print(e);
      return null;
    }

    return identityRecord;
  }

  Future queryAllIdentityRecords() async {
    var apiUrl = await _storageService.getLiveRpcUrl();

    try {
      var response = await http
          .get(apiUrl[0] + "/api/kira/gov/all_identity_records", headers: {'Access-Control-Allow-Origin': apiUrl[1]});

      var body = jsonDecode(response.body);

      for (var record in body['records']) {
        IdentityRecord identityRecord = IdentityRecord();
        identityRecord.address = record['address'];
        identityRecord.date = record['date'];
        identityRecord.id = record['id'];
        identityRecord.key = record['key'];
        identityRecord.value = record['value'];
        iRecords.add(identityRecord);
      }

      _storageService.setAllIdentityRecords(jsonEncode(iRecords));
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
        IdentityRecord identityRecord = IdentityRecord();
        identityRecord.address = record['address'];
        identityRecord.date = record['date'];
        identityRecord.id = record['id'];
        identityRecord.key = record['key'];
        identityRecord.value = record['value'];
        iRecords.add(identityRecord);
      }

      // _storageService.setAllIdentityRecords(jsonEncode(iRecords));
    } catch (e) {
      print(e);
      return;
    }
  }
}

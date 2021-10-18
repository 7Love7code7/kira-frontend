import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class IdentityRegistrarService {
  final _storageService = getIt<StorageService>();

  List<IdentityRegistrar> iRecords = [];

  void initialize() async {
    iRecords = await _storageService.getAllIdentityRegistrarRecords();
  }

  Future getAllIdentityRegistrarRecords() async {
    var apiUrl = await _storageService.getLiveRpcUrl();

    try {
      var response = await http
          .get(apiUrl[0] + "/api/kira/gov/all_identity_records", headers: {'Access-Control-Allow-Origin': apiUrl[1]});

      var body = jsonDecode(response.body);

      for (var record in body['records']) {
        IdentityRegistrar identityRegistrar = IdentityRegistrar();
        identityRegistrar.address = record['address'];
        identityRegistrar.date = record['date'];
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
}

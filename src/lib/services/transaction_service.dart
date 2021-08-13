import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class TransactionService {
  final _storageService = getIt<StorageService>();

  String currentAddress;
  List<Transaction> transactions = [];

  void initialize() async {
    Account currentAccount = await _storageService.getCurrentAccount();
    currentAddress = currentAccount.hexAddress;
    transactions = await _storageService.getTransactions(currentAddress);
  }

  Future<Transaction> getTransaction({hash}) async {
    if (hash.length < 64) return null;

    Transaction transaction = Transaction();

    var apiUrl = await _storageService.getLiveRpcUrl();
    var response = await http.get(apiUrl[0] + "/cosmos/txs/$hash", headers: {'Access-Control-Allow-Origin': apiUrl[1]});
    var body = jsonDecode(response.body);
    if (body['message'] == "Internal error") return null;

    transaction.hash = "0x" + body['hash'];
    transaction.gas = body['gas_used'];
    transaction.status = "confirmed";
    transaction.time = body[hash] != null ? body[hash]['time'] : 0;

    for (var events in body['tx_result']['events']) {
      for (var attribute in events['attributes']) {
        String key = attribute['key'];
        String value = attribute['value'];

        key = utf8.decode(base64Decode(key));
        value = utf8.decode(base64Decode(value));

        if (key == "action") transaction.action = value;
        if (key == "sender") transaction.sender = value;
        if (key == "recipient") transaction.recipient = value;
        if (key == "amount") {
          transaction.amount = value.split(new RegExp(r'[^0-9]+')).first;
          transaction.token = value.split(new RegExp(r'[^a-z]+')).last;
        }
        transaction.isNew = false;
      }
    }

    return transaction;
  }

  Future<bool> getTransactions(String address) async {
    currentAddress = address;
    int max = 10;
    List<Transaction> _transactions = [];

    List<String> apiUrl = await _storageService.getLiveRpcUrl();

    print("CORS ORIGIN: ${apiUrl[1]}");

    try {
      var response = await http.get(apiUrl[0] + "/withdraws?account=$address&type=all&max=$max",
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});

      Map<String, dynamic> withdrawTxs = jsonDecode(response.body);

      for (final hash in withdrawTxs.keys) {
        Transaction transaction = Transaction();

        transaction.hash = hash;
        transaction.status = "confirmed";
        transaction.time = withdrawTxs[hash] != null ? withdrawTxs[hash]['time'] : 0;

        var txs = withdrawTxs[hash]['txs'] ?? List.empty();
        if (txs.length == 0) continue;
        transaction.token = txs[0]['denom'];
        transaction.amount = txs[0]['amount'].toString();
        transaction.action = 'Withdraw';
        transaction.recipient = txs[0]['address'];

        _transactions.add(transaction);
      }
    } catch (e) {
      print(e);
      return false;
    }

    try {
      var response = await http.get(apiUrl[0] + "/deposits?account=$address&type=all&max=$max",
          headers: {'Access-Control-Allow-Origin': apiUrl[1]});

      Map<String, dynamic> depositTxs = jsonDecode(response.body);

      for (final hash in depositTxs.keys) {
        Transaction transaction = Transaction();

        transaction.hash = hash;
        transaction.status = "confirmed";
        transaction.time = depositTxs[hash] != null ? depositTxs[hash]['time'] : 0;

        var txs = depositTxs[hash]['txs'] ?? List.empty();
        if (txs.length == 0) continue;
        transaction.token = txs[0]['denom'];
        transaction.amount = txs[0]['amount'].toString();
        transaction.action = 'Deposit';
        transaction.sender = txs[0]['address'];

        _transactions.add(transaction);
      }
    } catch (e) {
      print(e);
      return false;
    }

    var ucResponse =
        await http.get(apiUrl[0] + "/unconfirmed_txs", headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    Map<String, dynamic> ucBody = jsonDecode(ucResponse.body);

    for (final tx in ucBody['txs']) {
      Transaction transaction = Transaction();
      transaction.hash = "-";
      transaction.status = 'unconfirmed';
      transaction.memo = tx['memo'];
      transaction.gas = tx['gas'];

      _transactions.add(transaction);
    }

    transactions = _transactions;
    _storageService.setTransactions(currentAddress, jsonEncode(transactions));

    return true;
  }

  Future<List<Transaction>> fetchTransactions(String address, bool isWithdrawal) async {
    List<Transaction> transactions = [];
    int max = 10;
    List<String> apiUrl = await _storageService.getLiveRpcUrl();

    String url = isWithdrawal == true ? "withdraws" : "deposits";
    String bech32Address = address;

    var response = await http.get(apiUrl[0] + "/$url?account=$bech32Address&&type=all&&max=$max",
        headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    Map<String, dynamic> body = jsonDecode(response.body);

    for (final hash in body.keys) {
      Transaction transaction = Transaction();

      transaction.hash = hash;
      transaction.status = "confirmed";
      transaction.time = body[hash] != null ? body[hash]['time'] : 0;

      var txs = body[hash]['txs'] ?? List.empty();
      if (txs.length == 0) continue;
      transaction.token = txs[0]['denom'];
      transaction.amount = txs[0]['amount'].toString();
      transaction.action = isWithdrawal == true ? 'Withdraw' : 'Deposit';

      if (isWithdrawal == true) {
        transaction.recipient = txs[0]['address'];
      } else {
        transaction.sender = txs[0]['address'];
      }

      transactions.add(transaction);
    }

    var ucResponse =
        await http.get(apiUrl[0] + "/unconfirmed_txs", headers: {'Access-Control-Allow-Origin': apiUrl[1]});

    Map<String, dynamic> ucBody = jsonDecode(ucResponse.body);

    for (final tx in ucBody['txs']) {
      Transaction transaction = Transaction();
      transaction.hash = "-";
      transaction.status = 'unconfirmed';
      transaction.memo = tx['memo'];
      transaction.gas = tx['gas'];

      transactions.add(transaction);
    }

    return transactions;
  }
}

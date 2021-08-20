import 'dart:convert';
import 'package:blake_hash/blake_hash.dart';
import 'package:bip39/bip39.dart' as bip39;

import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';
import 'package:kira_auth/utils/export.dart';

class AccountService {
  final _storageService = getIt<StorageService>();

  Account currentAccount;
  List<Account> accounts = [];

  void initialize() async {
    currentAccount = await _storageService.getCurrentAccount();
    accounts = await _storageService.getAccountData();
  }

  Future<void> setCurrentAccount(Account account) async {
    currentAccount = account;
    await _storageService.setCurrentAccount(account != null ? account.toJsonString() : "");
  }

  Future<Account> createNewAccount(String password, String accountName) async {
    Account account;

    // Generate Mnemonic for creating a new account
    String mnemonic = bip39.generateMnemonic(strength: 256);
    List<String> wordList = mnemonic.split(' ');
    List<int> bytes = utf8.encode(password);

    var apiUrl = await _storageService.getLiveRpcUrl();

    // Get hash value of password and use it to encrypt mnemonic
    var hashDigest = Blake256().update(bytes).digest();

    final networkInfo = NetworkInfo(
      bech32Hrp: "kira",
      lcdUrl: apiUrl[0] + "/cosmos",
    );

    account = Account.derive(wordList, networkInfo);

    account.secretKey = String.fromCharCodes(hashDigest);

    // Encrypt Mnemonic with AES-256 algorithm
    account.encryptedMnemonic = encryptAESCryptoJS(mnemonic, account.secretKey);
    account.checksum = encryptAESCryptoJS('kira', account.secretKey);
    account.name = accountName;

    await _storageService.setCurrentAccount(account.toString());
    return account;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/service_manager.dart';
import 'package:kira_auth/config.dart';

class GlobalScreen extends StatefulWidget {
  @override
  _GlobalScreenState createState() {
    return new _GlobalScreenState();
  }
}

class _GlobalScreenState extends State<GlobalScreen> {
  final _statusService = getIt<StatusService>();
  final _storageService = getIt<StorageService>();
  final _tokenService = getIt<TokenService>();
  final _transactionService = getIt<TransactionService>();
  final _accountService = getIt<AccountService>();

  Timer timer;

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    fetchData(true);
    timer = Timer.periodic(Duration(minutes: 2), (Timer t) => {fetchData(false)});

    _storageService.checkPasswordExpired().then((success) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/account');
      }
    });
  }

  void fetchData(bool isFirst) async {
    Account currentAccount = await _storageService.getCurrentAccount();

    if (isFirst) {
      _statusService.initialize();
      _tokenService.initialize();
      _transactionService.initialize();
      _accountService.initialize();

      currentAccount = _accountService.currentAccount;
      if (currentAccount != null) {
        BlocProvider.of<ValidatorBloc>(context).add(GetCachedValidators(currentAccount.hexAddress));
      }
    }

    await _statusService.getNodeStatus();
    BlocProvider.of<NetworkBloc>(context).add(SetNetworkInfo(_statusService.nodeInfo.network, _statusService.rpcUrl));

    List<String> rpcUrl = await _storageService.getLiveRpcUrl();

    if (rpcUrl[0].isEmpty) {
      bool isLoggedIn = await _storageService.getLoginStatus();
      if (!isLoggedIn) return;
      await loadInterxURL();
    }

    await _tokenService.getAvailableFaucetTokens();
    if (currentAccount != null) {
      await _tokenService.getTokens(currentAccount.bech32Address);
      await _transactionService.getTransactions(currentAccount.bech32Address);
    }

    print("--- SOS --- ${rpcUrl[0]}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: HeaderWrapper(
            childWidget: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[],
              ),
            )));
  }
}

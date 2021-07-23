import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/utils/cache.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/config.dart';

class GlobalScreen extends StatefulWidget {
  @override
  _GlobalScreenState createState() {
    return new _GlobalScreenState();
  }
}

class _GlobalScreenState extends State<GlobalScreen> {
  Account currentAccount;
  Timer timer;

  @override
  void initState() {
    super.initState();

    fetchData(true);
    timer = Timer.periodic(Duration(minutes: 2), (Timer t) => {fetchData(false)});

    getFeeTokenFromCache();
    getCurrentAccountFromCache();

    checkPasswordExpired().then((success) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/account');
      }
    });
  }

  void fetchData(bool isFirst) async {
    if (isFirst) {
      await StatusService().getNodeStatus();
    }

    List<String> rpcUrl = await getLiveRpcUrl();

    if (rpcUrl[0].isEmpty) {
      bool isLoggedIn = await getLoginStatus();
      if (!isLoggedIn) return;
      await loadInterxURL();
    }

    print("--- SOS --- ${rpcUrl[0]}");
  }

  void getCurrentAccountFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String currentAccountString = prefs.getString('CURRENT_ACCOUNT');

    if (currentAccountString != null && currentAccountString != "") {
      currentAccount = Account.fromString(currentAccountString);
    }

    if (BlocProvider.of<AccountBloc>(context).state.currentAccount == null && currentAccount != null) {
      BlocProvider.of<AccountBloc>(context).add(SetCurrentAccount(currentAccount));
      BlocProvider.of<ValidatorBloc>(context).add(GetCachedValidators(currentAccount.hexAddress));
    }
  }

  void getFeeTokenFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String feeTokenString = prefs.getString('FEE_TOKEN');
    Token feeToken;

    if (feeTokenString != null && feeTokenString != "") {
      feeToken = Token.fromString(feeTokenString);
    }

    if (BlocProvider.of<TokenBloc>(context).state.feeToken == null && feeToken != null) {
      BlocProvider.of<TokenBloc>(context).add(SetFeeToken(feeToken));
    }
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

// import 'dart:html';
import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class LoginWithMnemonicScreen extends StatefulWidget {
  @override
  _LoginWithMnemonicScreenState createState() => _LoginWithMnemonicScreenState();
}

class _LoginWithMnemonicScreenState extends State<LoginWithMnemonicScreen> {
  AccountService _accountService = getIt<AccountService>();
  String mnemonicError = "";
  bool isNetworkHealthy = false;

  FocusNode mnemonicFocusNode;
  TextEditingController mnemonicController;

  @override
  void initState() {
    super.initState();

    mnemonicFocusNode = FocusNode();
    mnemonicController = TextEditingController();

    getNodeStatus();
  }

  @override
  void dispose() {
    mnemonicController.dispose();
    super.dispose();
  }

  void getNodeStatus() async {
    final _statusService = getIt<StatusService>();
    bool networkHealth = _statusService.isNetworkHealthy;
    NodeInfo nodeInfo = _statusService.nodeInfo;

    if (nodeInfo == null) {
      final _storageService = getIt<StorageService>();
      nodeInfo = await _storageService.getNodeStatusData("NODE_INFO");
    }

    if (mounted) {
      setState(() {
        isNetworkHealthy = nodeInfo != null && nodeInfo.network.isNotEmpty ? networkHealth : false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: HeaderWrapper(
            isNetworkHealthy: isNetworkHealthy,
            childWidget: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.only(top: 50, bottom: 50),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      addHeaderTitle(),
                      addDescription(),
                      addMnemonic(),
                      ResponsiveWidget.isSmallScreen(context) ? addButtonsSmall() : addButtonsBig(),
                      ResponsiveWidget.isSmallScreen(context) ? SizedBox(height: 20) : SizedBox(height: 150),
                    ],
                  )),
            )));
  }

  Widget addHeaderTitle() {
    return Container(
        margin: EdgeInsets.only(bottom: 40),
        child: Text(
          Strings.loginWithMnemonic,
          textAlign: TextAlign.left,
          style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
        ));
  }

  Widget addDescription() {
    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Row(children: <Widget>[
          Expanded(
              child: Text(
            Strings.loginDescription,
            textAlign: TextAlign.left,
            style: TextStyle(color: KiraColors.green3, fontSize: 18),
          ))
        ]));
  }

  Widget addMnemonic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          hintText: Strings.mnemonicWords,
          labelText: Strings.mnemonicWords,
          focusNode: mnemonicFocusNode,
          controller: mnemonicController,
          textInputAction: TextInputAction.done,
          maxLines: 1,
          autocorrect: false,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.left,
          onChanged: (String text) {
            if (text == '') {
              setState(() {
                mnemonicError = "";
              });
            }
          },
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18.0,
            color: KiraColors.white,
            fontFamily: 'NunitoSans',
          ),
        ),
        if (mnemonicError.isNotEmpty) SizedBox(height: 15),
        if (mnemonicError.isNotEmpty)
          Container(
            alignment: AlignmentDirectional(0, 0),
            margin: EdgeInsets.only(top: 3),
            child: Text(mnemonicError,
                style: TextStyle(
                  fontSize: 14.0,
                  color: KiraColors.kYellowColor,
                  fontFamily: 'NunitoSans',
                  fontWeight: FontWeight.w400,
                )),
          ),
        SizedBox(height: 30),
      ],
    );
  }

  void onLogin() async {
    final _storageService = getIt<StorageService>();

    String mnemonic = mnemonicController.text;

    // Check if mnemonic is valid
    if (bip39.validateMnemonic(mnemonic) == false) {
      setState(() {
        mnemonicError = Strings.mnemonicWrong;
      });
      return;
    }

    List<Account> accounts = await _storageService.getAccountData();
    // print(accounts.length);
    // if (accounts.length == 0) {
    //   setState(() {
    //     mnemonicError = Strings.mnemonicWrong;
    //   });
    //   return;
    // }

    bool accountFound = false;
    Account fAccount;

    for (int i = 0; i < accounts.length; i++) {
      if (accounts[i].encryptedMnemonic == mnemonic) {
        fAccount = accounts[i];
        accountFound = true;
      }
    }

    if (accountFound == false) {
      fAccount = await _accountService.importAccount(mnemonic, "12345678", "Imported Account");
      _storageService.setAccountData(fAccount.toJsonString());
    } else {}

    await _accountService.setCurrentAccount(fAccount);
    BlocProvider.of<ValidatorBloc>(context).add(GetCachedValidators(fAccount.hexAddress));

    await _storageService.setPassword('12345678');
    await _storageService.setLoginStatus(true);

    Navigator.pushReplacementNamed(context, '/account');
  }

  Widget addButtonsSmall() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CustomButton(
              key: Key(Strings.login),
              text: Strings.login,
              height: 60,
              style: 2,
              onPressed: () {
                onLogin();
              },
            ),
            SizedBox(height: 30),
            CustomButton(
              key: Key(Strings.back),
              text: Strings.back,
              height: 60,
              style: 1,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ]),
    );
  }

  Widget addButtonsBig() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CustomButton(
              key: Key(Strings.back),
              text: Strings.back,
              width: 220,
              height: 60,
              style: 1,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            CustomButton(
              key: Key(Strings.login),
              text: Strings.login,
              width: 220,
              height: 60,
              style: 2,
              onPressed: () {
                onLogin();
              },
            ),
          ]),
    );
  }
}

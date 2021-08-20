// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:blake_hash/blake_hash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _accountService = getIt<AccountService>();
  final _storageService = getIt<StorageService>();
  final _tokenService = getIt<TokenService>();
  final _statusService = getIt<StatusService>();

  String accountId, origin, feeTokenTicker, notification = '';
  String expireTime = '0',
      error = '',
      accountNameError = '',
      rpcUrlError = '',
      currentPassword = '',
      currentRpcUrl = '';

  bool isError = true, isAccountEditEnabled = false, isValidatorEditEnabled = false, isNodeAdd = true;
  bool isNetworkHealthy = false;
  List<Account> accounts = [];
  List<String> validators = [];
  List<Token> tokens = [];
  Account currentAccount;

  FocusNode expireTimeFocusNode;
  TextEditingController expireTimeController;

  FocusNode feeAmountNode;
  TextEditingController feeAmountController;

  FocusNode rpcUrlNode;
  TextEditingController rpcUrlController;

  FocusNode accountNameNode;
  TextEditingController accountNameController;

  FocusNode passwordNode;
  TextEditingController passwordController;

  @override
  void initState() {
    super.initState();

    expireTimeFocusNode = FocusNode();
    expireTimeController = TextEditingController();

    feeAmountNode = FocusNode();
    feeAmountController = TextEditingController();
    feeAmountController.text = '1000';

    rpcUrlNode = FocusNode();
    rpcUrlController = TextEditingController();

    accountNameNode = FocusNode();
    accountNameController = TextEditingController();

    passwordNode = FocusNode();
    passwordController = TextEditingController();

    getNodeStatus();
    readCachedData();
    getCurrentAccount();
    getTokens();
  }

  void readCachedData() async {
    List<Account> cAccounts = await _storageService.getAccountData();
    String cPassword = await _storageService.getPassword();
    int cExpireTime = await _storageService.getExpireTime();
    int cFeeAmount = await _storageService.getFeeAmount();
    List<String> _validators = await _storageService.getValidators();

    print(_validators);
    var apiUrl = await _storageService.getLiveRpcUrl();
    String interxUrl = apiUrl[0];

    if (mounted) {
      setState(() {
        if (_validators.length == 0) {
          _validators.add(interxUrl);
        }
        currentRpcUrl = interxUrl;
        rpcUrlController.text = interxUrl;
        origin = apiUrl[1];

        accounts = cAccounts;
        validators = _validators;

        // Cached password
        currentPassword = cPassword;

        // Password expire time
        expireTime = (cExpireTime / 60000).toString();
        expireTimeController.text = expireTime;

        // Fee amount
        feeAmountController.text = cFeeAmount.toString();
      });
    }
  }

  void getTokens() async {
    Token feeToken = await _storageService.getFeeToken();

    Account curAccount;
    curAccount = _accountService.currentAccount;
    if (curAccount == null) {
      curAccount = await _storageService.getCurrentAccount();
    }

    if (curAccount != null) {
      List<Token> _tokenBalance = _tokenService.tokens;

      if (_tokenBalance.length == 0) {
        _tokenBalance = await _storageService.getTokenBalance(curAccount.bech32Address);
      }

      if (_tokenBalance.length == 0) {
        await _tokenService.getTokens(curAccount.bech32Address);
        _tokenBalance = _tokenService.tokens;
      }

      if (mounted) {
        setState(() {
          tokens = _tokenBalance;
          feeTokenTicker = feeToken != null
              ? feeToken.ticker
              : _tokenBalance.length > 0
                  ? _tokenBalance[0].ticker
                  : null;
        });
      }
    }
  }

  void getNodeStatus() async {
    bool networkHealth = _statusService.isNetworkHealthy;
    NodeInfo nodeInfo = _statusService.nodeInfo;

    if (nodeInfo == null) {
      nodeInfo = await _storageService.getNodeStatusData("NODE_INFO");
    }

    if (mounted) {
      setState(() {
        isNetworkHealthy = nodeInfo == null ? false : networkHealth;
      });
    }
  }

  getCurrentAccount() async {
    Account curAccount = _accountService.currentAccount;

    if (_accountService.currentAccount == null) {
      curAccount = await _storageService.getCurrentAccount();
    }

    if (mounted) {
      accountNameController.text = curAccount.name;
      setState(() {
        currentAccount = curAccount;
        accountId = curAccount.encryptedMnemonic;
      });
    }
  }

  @override
  void dispose() {
    expireTimeController.dispose();
    feeAmountController.dispose();
    rpcUrlController.dispose();
    accountNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void exportToKeyFile() async {
    var index = accounts.indexWhere((item) => item.encryptedMnemonic == accountId);
    if (index < 0) return;
    Account selectedAccount = new Account.fromJson(accounts[index].toJson());

    List<int> passwordBytes = utf8.encode(currentPassword);
    var hashDigest = Blake256().update(passwordBytes).digest();
    String secretKey = String.fromCharCodes(hashDigest);

    selectedAccount.secretKey = secretKey;
    selectedAccount.encryptedMnemonic = encryptAESCryptoJS(selectedAccount.encryptedMnemonic, secretKey);
    selectedAccount.checksum = encryptAESCryptoJS(selectedAccount.checksum, secretKey);

    final text = selectedAccount.toJsonString();
    // prepare
    final bytes = utf8.encode(text);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = selectedAccount.name + '.json';
    html.document.body.children.add(anchor);

    // download
    anchor.click();

    // cleanup
    html.document.body.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  void onUpdate() async {
    if (expireTimeController.text == null) return;

    setState(() {
      notification = Strings.checkingNodeStatus;
      isError = true;
    });

    int minutes = int.tryParse(expireTimeController.text);
    if (minutes == null) {
      setState(() {
        notification = Strings.invalidExpireTime;
        isError = true;
      });
      return;
    }

    int feeAmount = int.tryParse(feeAmountController.text);
    if (feeAmount == null) {
      setState(() {
        notification = Strings.invalidFeeAmount;
        isError = true;
      });
      return;
    }

    if (currentRpcUrl == null || currentRpcUrl.length == 0) {
      setState(() {
        notification = Strings.emptyRpcUrl;
        isError = true;
      });
      return;
    }

    await _storageService.setExpireTime(Duration(minutes: minutes));
    await _storageService.setInterxRPCUrl(currentRpcUrl);
    await _storageService.setLiveRpcUrl(currentRpcUrl, origin);
    await _storageService.setFeeAmount(feeAmount);

    Account currentAccount = accounts.where((e) => e.encryptedMnemonic == accountId).toList()[0];
    await _accountService.setCurrentAccount(currentAccount);

    Token feeToken = tokens.where((e) => e.ticker == feeTokenTicker).toList()[0];
    _tokenService.setFeeToken(feeToken);

    await _storageService.setValidators(validators);

    await _statusService.getNodeStatus();
    BlocProvider.of<NetworkBloc>(context).add(SetNetworkInfo(_statusService.nodeInfo.network, _statusService.rpcUrl));

    setState(() {
      notification = Strings.updateSuccess;
      isError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _storageService.checkPasswordExpired().then((success) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return Scaffold(
        body: HeaderWrapper(
            isNetworkHealthy: isNetworkHealthy,
            childWidget: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(vertical: ResponsiveWidget.isSmallScreen(context) ? 10 : 50),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      addHeaderTitle(),
                      addAccounts(),
                      addAccountButtons(context),
                      if (isAccountEditEnabled) addAccountName(),
                      if (isAccountEditEnabled) addAccountEditButtons(),
                      addValidators(),
                      addValidatorButtons(context),
                      if (isValidatorEditEnabled) addCustomRPC(),
                      if (isValidatorEditEnabled) addValidatorEditButtons(),
                      addErrorMessage(),
                      if (tokens.length > 0) addFeeToken(),
                      addFeeAmount(),
                      addExpirePassword(),
                      ResponsiveWidget.isSmallScreen(context) ? addButtonsSmall() : addButtonsBig(),
                      addGoBackButton(),
                    ],
                  )),
            )));
  }

  Widget addHeaderTitle() {
    return Container(
        margin: EdgeInsets.only(bottom: 40),
        child: Text(
          Strings.settings,
          textAlign: TextAlign.left,
          style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
        ));
  }

  Widget addAccounts() {
    return Container(
        decoration: BoxDecoration(
            border: Border.all(width: 2, color: KiraColors.kPurpleColor),
            color: KiraColors.transparent,
            borderRadius: BorderRadius.circular(9)),
        // dropdown below..
        child: DropdownButtonHideUnderline(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.only(top: 10, left: 15, bottom: 0),
                child: Text(Strings.availableAccounts, style: TextStyle(color: KiraColors.kGrayColor, fontSize: 12)),
              ),
              ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                    dropdownColor: KiraColors.kPurpleColor,
                    value: accountId,
                    icon: Icon(Icons.arrow_drop_down),
                    iconSize: 32,
                    underline: SizedBox(),
                    onChanged: (String accId) {
                      var curIndex = accounts.indexWhere((e) => e.encryptedMnemonic == accId);
                      if (curIndex < 0) return;
                      Account selectedAccount = new Account.fromJson(accounts[curIndex].toJson());
                      setState(() {
                        accountId = accId;
                        accountNameController.text = selectedAccount.name;
                      });
                    },
                    items: accounts.map<DropdownMenuItem<String>>((Account data) {
                      return DropdownMenuItem<String>(
                        value: data.encryptedMnemonic,
                        child: Container(
                            height: 25,
                            alignment: Alignment.topCenter,
                            child: Text(data.name, style: TextStyle(color: KiraColors.white, fontSize: 18))),
                      );
                    }).toList()),
              ),
            ],
          ),
        ));
  }

  Widget addValidators() {
    return Container(
        decoration: BoxDecoration(
            border: Border.all(width: 2, color: KiraColors.kPurpleColor),
            color: KiraColors.transparent,
            borderRadius: BorderRadius.circular(9)),
        // dropdown below..
        child: DropdownButtonHideUnderline(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.only(top: 10, left: 15, bottom: 0),
                child: Text(Strings.validators, style: TextStyle(color: KiraColors.kGrayColor, fontSize: 12)),
              ),
              ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                    dropdownColor: KiraColors.kPurpleColor,
                    value: currentRpcUrl,
                    icon: Icon(Icons.arrow_drop_down),
                    iconSize: 32,
                    underline: SizedBox(),
                    onChanged: (String rpcUrl) {
                      setState(() {
                        currentRpcUrl = rpcUrl;
                        rpcUrlController.text = rpcUrl;
                      });
                    },
                    items: validators.map<DropdownMenuItem<String>>((String rpcUrl) {
                      return DropdownMenuItem<String>(
                        value: rpcUrl,
                        child: Container(
                            height: 25,
                            alignment: Alignment.topCenter,
                            child: Text(getIPOnly(rpcUrl), style: TextStyle(color: KiraColors.white, fontSize: 18))),
                      );
                    }).toList()),
              ),
            ],
          ),
        ));
  }

  Widget addAccountButtons(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(top: 8, bottom: 20),
        alignment: Alignment.centerLeft,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
          InkWell(
              onTap: () {
                setState(() {
                  isAccountEditEnabled = true;
                });
              },
              child: Text(
                Strings.edit,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: KiraColors.green3.withOpacity(0.9),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              )),
          SizedBox(width: 10),
          InkWell(
              onTap: () {
                if (accounts.isEmpty) return;
                if (accountId == null || accountId == '') return;

                showConfirmationDialog(context, true);
              },
              child: Text(
                Strings.remove,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: KiraColors.green3.withOpacity(0.9),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              )),
        ]));
  }

  Widget addAccountName() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(
        hintText: Strings.accountName,
        labelText: Strings.accountName,
        focusNode: accountNameNode,
        controller: accountNameController,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        autocorrect: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: KiraColors.white,
          fontFamily: 'NunitoSans',
        ),
      ),
      SizedBox(height: 10),
    ]);
  }

  Widget addAccountEditButtons() {
    return Container(
        margin: EdgeInsets.only(top: 5, bottom: 25),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
                onTap: () {
                  var accountName = accountNameController.text;
                  if (accountName == "") {
                    setState(() {
                      accountNameError = Strings.accountNameInvalid;
                    });
                    return;
                  }

                  var index = accounts.indexWhere((item) => item.encryptedMnemonic == accountId);
                  accounts.elementAt(index).name = accountName;

                  String updatedString = "";

                  for (int i = 0; i < accounts.length; i++) {
                    updatedString += accounts[i].toJsonString();
                    if (i < accounts.length - 1) {
                      updatedString += "---";
                    }
                  }

                  _storageService.removeCachedAccount();
                  _storageService.setAccountData(updatedString);

                  Account currentAccount = accounts.where((e) => e.encryptedMnemonic == accountId).toList()[0];
                  _accountService.setCurrentAccount(currentAccount);

                  setState(() {
                    isAccountEditEnabled = false;
                  });
                },
                child: Text(
                  Strings.save,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: KiraColors.blue1.withOpacity(0.9),
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                )),
            if (accountNameError.isNotEmpty)
              Text(accountNameError,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: KiraColors.kYellowColor,
                  ))
          ],
        ));
  }

  Widget addCustomRPC() {
    return Container(
        margin: EdgeInsets.only(top: 15),
        alignment: Alignment.centerLeft,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppTextField(
            hintText: Strings.rpcURL,
            labelText: Strings.rpcURL,
            focusNode: rpcUrlNode,
            controller: rpcUrlController,
            textInputAction: TextInputAction.done,
            maxLines: 1,
            autocorrect: false,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.left,
            onChanged: (String text) {
              // setState(() {
              // var urlPattern = r"^(?:[0-9]{1,3}\.){3}[0-9]{1,3}\:[0-9]{1,5}$";
              // RegExp regex = new RegExp(urlPattern, caseSensitive: false);

              // if (!regex.hasMatch(text)) {
              //   error = Strings.invalidUrl;
              // } else {
              //   error = "";
              // }
              // });
            },
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: KiraColors.white,
              fontFamily: 'NunitoSans',
            ),
          ),
          SizedBox(height: 10),
        ]));
  }

  Widget addValidatorEditButtons() {
    return Container(
        margin: EdgeInsets.only(top: 0, bottom: 10),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
              InkWell(
                  onTap: () async {
                    var newRpcUrl = rpcUrlController.text;
                    setState(() {
                      rpcUrlError = Strings.checkingNodeStatus;
                    });

                    newRpcUrl = newRpcUrl.trim();
                    String checkedUrl = await _statusService.checkNodeStatus(newRpcUrl);

                    if (newRpcUrl == "" || checkedUrl == "invalid") {
                      setState(() {
                        rpcUrlError = Strings.invalidRpcUrl;
                      });
                      return;
                    }

                    var index = validators.indexWhere((element) => element.contains(newRpcUrl));

                    setState(() {
                      if (isNodeAdd && index == -1) {
                        validators.add(checkedUrl);
                        currentRpcUrl = checkedUrl;
                      } else {
                        var index = validators.indexWhere((item) => item == currentRpcUrl);
                        validators[index] = checkedUrl;
                        currentRpcUrl = checkedUrl;
                      }

                      rpcUrlError = "";
                      isValidatorEditEnabled = false;
                    });
                  },
                  child: Text(
                    Strings.save,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: KiraColors.blue1.withOpacity(0.9),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  )),
              SizedBox(width: 10),
              InkWell(
                  onTap: () {
                    rpcUrlController.text = currentRpcUrl;
                    setState(() {
                      isValidatorEditEnabled = false;
                    });
                  },
                  child: Text(
                    Strings.cancel,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: KiraColors.blue1.withOpacity(0.9),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ))
            ]),
            if (rpcUrlError.isNotEmpty)
              Text(rpcUrlError,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: KiraColors.kYellowColor,
                  ))
          ],
        ));
  }

  Widget addValidatorButtons(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(top: 8, bottom: 5),
        alignment: Alignment.centerLeft,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
          InkWell(
              onTap: () {
                rpcUrlController.text = "";
                setState(() {
                  isValidatorEditEnabled = true;
                  isNodeAdd = true;
                });
              },
              child: Text(
                Strings.add,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: KiraColors.green3.withOpacity(0.9),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              )),
          SizedBox(width: 10),
          InkWell(
              onTap: () {
                rpcUrlController.text = currentRpcUrl;
                setState(() {
                  isValidatorEditEnabled = true;
                  isNodeAdd = false;
                });
              },
              child: Text(
                Strings.edit,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: KiraColors.green3.withOpacity(0.9),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              )),
          SizedBox(width: 10),
          InkWell(
              onTap: () {
                if (validators.isEmpty) return;
                if (currentRpcUrl == null || currentRpcUrl == '') return;

                showConfirmationDialog(context, false);
              },
              child: Text(
                Strings.remove,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: KiraColors.green3.withOpacity(0.9),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              )),
        ]));
  }

  Widget addErrorMessage() {
    return Container(
        // padding: EdgeInsets.symmetric(horizontal: 20),
        margin: EdgeInsets.only(bottom: error.isNotEmpty ? 30 : 0),
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  alignment: AlignmentDirectional(0, 0),
                  child: Text(error == null ? "" : error,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: KiraColors.kYellowColor,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ],
        ));
  }

  Widget addFeeToken() {
    return Container(
        margin: EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
            border: Border.all(width: 2, color: KiraColors.kPurpleColor),
            color: KiraColors.transparent,
            borderRadius: BorderRadius.circular(9)),
        // dropdown below..
        child: DropdownButtonHideUnderline(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.only(top: 10, left: 15, bottom: 0),
                child: Text(Strings.tokenForFeePayment, style: TextStyle(color: KiraColors.kGrayColor, fontSize: 12)),
              ),
              ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                    dropdownColor: KiraColors.kPurpleColor,
                    value: feeTokenTicker,
                    icon: Icon(Icons.arrow_drop_down),
                    iconSize: 32,
                    underline: SizedBox(),
                    onChanged: (String ticker) {
                      setState(() {
                        feeTokenTicker = ticker;
                      });
                    },
                    items: tokens.map<DropdownMenuItem<String>>((Token token) {
                      return DropdownMenuItem<String>(
                        value: token.ticker,
                        child: Container(
                            height: 25,
                            alignment: Alignment.topCenter,
                            child: Text(token.ticker, style: TextStyle(color: KiraColors.white, fontSize: 18))),
                      );
                    }).toList()),
              ),
            ],
          ),
        ));
  }

  Widget addFeeAmount() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(
        hintText: Strings.feeAmount,
        labelText: Strings.feeAmount,
        focusNode: feeAmountNode,
        controller: feeAmountController,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        autocorrect: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
        onChanged: (String text) {
          if (text == '') {
            setState(() {
              notification = "";
            });
          }
        },
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: KiraColors.white,
          fontFamily: 'NunitoSans',
        ),
      ),
      SizedBox(height: 30),
    ]);
  }

  Widget addExpirePassword() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(
        labelText: Strings.passwordExpiresIn,
        focusNode: expireTimeFocusNode,
        controller: expireTimeController,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        autocorrect: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
        onChanged: (String password) {
          if (password != "") {
            setState(() {
              notification = "";
            });
          }
        },
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: KiraColors.white,
          fontFamily: 'NunitoSans',
        ),
      ),
      if (notification != "") SizedBox(height: 10),
      if (notification != "")
        Container(
          alignment: AlignmentDirectional(0, 0),
          margin: EdgeInsets.only(top: 3),
          child: Text(notification,
              style: TextStyle(
                fontSize: 14.0,
                color: isError ? KiraColors.kYellowColor : KiraColors.green3,
                fontFamily: 'NunitoSans',
                fontWeight: FontWeight.w600,
              )),
        ),
      SizedBox(height: 50),
    ]);
  }

  Widget addButtonsSmall() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CustomButton(
              key: Key(Strings.update),
              text: Strings.update,
              height: 60,
              style: 2,
              onPressed: () {
                onUpdate();
              },
            ),
            SizedBox(height: 30),
            CustomButton(
              key: Key(Strings.exportToKeyFile),
              text: Strings.exportToKeyFile,
              height: 60,
              style: 1,
              onPressed: () async {
                if (currentPassword == "12345678") {
                  showPasswordDialog(context);
                } else {
                  exportToKeyFile();
                }
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
              key: Key(Strings.exportToKeyFile),
              text: Strings.exportToKeyFile,
              width: 220,
              height: 60,
              style: 1,
              onPressed: () {
                if (currentPassword == "12345678") {
                  showPasswordDialog(context);
                } else {
                  exportToKeyFile();
                }
              },
            ),
            CustomButton(
              key: Key(Strings.update),
              text: Strings.update,
              width: 220,
              height: 60,
              style: 2,
              onPressed: () {
                onUpdate();
              },
            ),
          ]),
    );
  }

  Widget addGoBackButton() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      CustomButton(
        key: Key(Strings.back),
        text: Strings.back,
        fontSize: 18,
        height: 60,
        style: 1,
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/account');
        },
      )
    ]);
  }

  showConfirmationDialog(BuildContext context, bool isAccount) {
    // set up the buttons
    Widget noButton = TextButton(
      child: Text(
        Strings.no,
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );

    Widget yesButton = TextButton(
      child: Text(
        Strings.yes,
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      onPressed: () {
        if (isAccount) {
          var updated = accounts;
          updated.removeWhere((item) => item.encryptedMnemonic == accountId);

          String updatedString = "";

          for (int i = 0; i < updated.length; i++) {
            updatedString += updated[i].toJsonString();
            if (i < updated.length - 1) {
              updatedString += "---";
            }
          }

          setState(() {
            accounts = updated;
            accountId = accounts.length > 0 ? accounts[0].encryptedMnemonic : null;
          });

          _storageService.removeCachedAccount();
          _storageService.setAccountData(updatedString);

          if (updatedString.isEmpty) {
            _storageService.removePassword();
            Navigator.pushReplacementNamed(context, '/');
          }
        } else {
          var updated = validators;
          updated.removeWhere((item) => item == currentRpcUrl);

          setState(() {
            validators = updated;
            currentRpcUrl = validators.length > 0 ? validators[0] : null;
            rpcUrlController.text = currentRpcUrl;
          });

          if (updated.length == 0) {
            Navigator.pushReplacementNamed(context, '/');
          }
        }
        Navigator.of(context, rootNavigator: true).pop();
      },
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          contentWidgets: [
            Text(
              Strings.kiraNetwork,
              style: TextStyle(fontSize: 22, color: KiraColors.kPurpleColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              isAccount ? Strings.removeAccountConfirmation : Strings.removeValidatorConfirmation,
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 22,
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[yesButton, noButton]),
          ],
        );
      },
    );
  }

  showPasswordDialog(BuildContext context) {
    // set up the buttons
    Widget closeButton = TextButton(
      child: Text(
        Strings.close,
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );

    Widget yesButton = TextButton(
      child: Text(
        Strings.yes,
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      onPressed: () {
        exportToKeyFile();
      },
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          contentWidgets: [
            Text(
              Strings.kiraNetwork,
              style: TextStyle(fontSize: 22, color: KiraColors.kPurpleColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              Strings.inputPassword,
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 22,
            ),
            ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: TextField(
                    focusNode: passwordNode,
                    controller: passwordController,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    obscureText: true,
                    onChanged: (String password) {
                      if (password != "") {
                        setState(() {
                          currentPassword = password;
                        });
                      }
                    },
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 18.0, color: Colors.black),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        borderSide: BorderSide(color: KiraColors.kGrayColor.withOpacity(0.3), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide: BorderSide(color: KiraColors.kPurpleColor, width: 2),
                      ),
                    ))),
            SizedBox(
              height: 22,
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[yesButton, closeButton]),
          ],
        );
      },
    );
  }
}

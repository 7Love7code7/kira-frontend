// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';

import 'package:kira_auth/utils/export.dart';

import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';
import 'package:kira_auth/widgets/qrcode_scanner_dialog.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int i = 1;
  List<String> networkIds = [Strings.customNetwork];
  String networkId = Strings.customNetwork;
  String testedRpcUrl = "";
  bool isLoading = false, isHover = false, isNetworkHealthy = false, isRpcError = false;
  bool saifuQR = false;
  bool isHttp = false;
  bool localhostChecked = false;

  FocusNode rpcUrlNode;
  TextEditingController rpcUrlController;

  final _storageService = getIt<StorageService>();

  @override
  void initState() {
    super.initState();

    _storageService.getLiveRpcUrl().then((rpcUrl) {
      var _networkId = BlocProvider.of<NetworkBloc>(context).state.networkId;
      if (rpcUrl != null && rpcUrl.isNotEmpty && rpcUrl[0].isNotEmpty) {
        this.setState(() {
          networkId = _networkId;
          isNetworkHealthy = true;
          testedRpcUrl = rpcUrl[0];
          isHttp = !rpcUrl[0].replaceAll("https://cors-anywhere.kira.network/", "").startsWith("https");
          isRpcError = false;
        });
      } else {
        onConnectPressed('localhost');
      }
    });

    _storageService.setTopBarStatus(false);
    _storageService.setLoginStatus(false);
    rpcUrlNode = FocusNode();
    rpcUrlController = TextEditingController();
    initializeValues();
  }

  void initializeValues() {
    _storageService.setLastSearchedAccount("");
    _storageService.setTopbarIndex(0);
  }

  @override
  void dispose() {
    rpcUrlController.dispose();
    rpcUrlNode.dispose();
    super.dispose();
  }

  void getNodeStatus() async {
    final _statusService = getIt<StatusService>();
    await _statusService.getNodeStatus();

    var rpcUrl = await _storageService.getLiveRpcUrl();

    if (mounted) {
      try {
        bool networkHealth = _statusService.isNetworkHealthy;
        NodeInfo nodeInfo = _statusService.nodeInfo;
        BlocProvider.of<NetworkBloc>(context)
            .add(SetNetworkInfo(_statusService.nodeInfo.network, _statusService.rpcUrl));

        if (nodeInfo != null && nodeInfo.network.isNotEmpty) {
          setState(() {
            if (!networkIds.contains(nodeInfo.network)) {
              networkIds.add(nodeInfo.network);
            }
            networkId = nodeInfo.network;
            isNetworkHealthy = networkHealth;
            testedRpcUrl = getIPOnly(rpcUrl[0]);
            isHttp = !rpcUrl[0].replaceAll("https://cors-anywhere.kira.network/", "").startsWith("https");
            isRpcError = false;
          });
        } else {
          isNetworkHealthy = false;
        }
        isLoading = false;
      } catch (e) {
        print("ERROR OCCURED");
        setState(() {
          testedRpcUrl = localhostChecked ? getIPOnly(rpcUrl[0]) : '';
          isNetworkHealthy = false;
          isLoading = false;
          isRpcError = true;
          localhostChecked = true;
        });
      }
    }
  }

  void disconnect() {
    if (mounted) {
      setState(() {
        isRpcError = false;
        isNetworkHealthy = false;
      });
      rpcUrlController.text = "";
      _storageService.setInterxRPCUrl("");
      // Future.delayed(const Duration(milliseconds: 500), () async {
      //   checkNodeStatus();
      // });
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
                      if (isNetworkHealthy == false) addNetworks(context),
                      if (isNetworkHealthy == false && networkId == Strings.customNetwork)
                        addCustomRPC(),
                      if (isLoading == true) addLoadingIndicator(),
                      // addErrorMessage(),
                      if (networkId == Strings.customNetwork &&
                          isNetworkHealthy == false &&
                          isLoading == false)
                        addConnectButton(context),
                      isNetworkHealthy == true && isLoading == false
                          ? Column(
                              children: [
                                addLoginButtonsSmall(),
                                addCreateNewAccount(),
                              ],
                            )
                          : Container(),
                    ],
                  ),
                ))));
  }

  Widget addHeaderTitle() {
    bool connected = networkId != null && networkId != '' && networkId != Strings.customNetwork;
    String headerTitle = connected ? 'You are connected to ' + networkId : Strings.connect;
    headerTitle = isRpcError && testedRpcUrl != "" ? Strings.failedToConnect : headerTitle;

    return Container(
        margin: EdgeInsets.only(bottom: 40),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headerTitle,
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: isRpcError && testedRpcUrl != "" ? KiraColors.danger : KiraColors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900),
              ),
              if ((isRpcError && testedRpcUrl != "") || isHttp) SizedBox(height: 20),
              if (isHttp) Container(
                margin: EdgeInsets.only(left: 30),
                child: Text(
                  Strings.httpConnected,
                  textAlign: TextAlign.left,
                  style: TextStyle(color: KiraColors.kYellowColor, fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              if (isRpcError && testedRpcUrl != "")
                Text(
                  "Node with address " + testedRpcUrl + " could not be reached",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: KiraColors.danger, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              SizedBox(height: 20),
              Text(
                connected ? Strings.selectLoginOption : Strings.selectFullNode,
                textAlign: TextAlign.left,
                style:
                    TextStyle(color: KiraColors.green3, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              if (!connected) SizedBox(height: 15),
              if (!connected)
                Text(
                  Strings.requireSSL,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: KiraColors.white.withOpacity(0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w300),
                )
            ]));
  }

  Widget addNetworks(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Container(
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
                  child: Text(Strings.availableNetworks,
                      style: TextStyle(color: KiraColors.kGrayColor, fontSize: 12)),
                ),
                ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                      dropdownColor: KiraColors.kPurpleColor,
                      value: networkId,
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 32,
                      underline: SizedBox(),
                      onChanged: (String netId) {
                        if (mounted) {
                          setState(() {
                            networkId = netId;
                            if (networkId == Strings.customNetwork) {
                              disconnect();
                              networkIds.clear();
                              networkIds.add(Strings.customNetwork);
                            }
                          });
                        }
                      },
                      items: networkIds.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Container(
                              height: 25,
                              alignment: Alignment.topCenter,
                              child: Text(value,
                                  style: TextStyle(color: KiraColors.white, fontSize: 18))),
                        );
                      }).toList()),
                ),
              ],
            ),
          )),
    );
  }

  Widget addCustomRPC() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppTextField(
        labelText: Strings.rpcURL,
        focusNode: rpcUrlNode,
        controller: rpcUrlController,
        textInputAction: TextInputAction.done,
        isWrong: isRpcError && testedRpcUrl != "",
        maxLines: 1,
        autocorrect: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
        onChanged: (String text) {
          if (mounted) {
            setState(() {
              isNetworkHealthy = false;
              if (text == "") isRpcError = false;
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
      SizedBox(height: 30)
    ]);
  }

  Widget addConnectButton(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(bottom: 40),
        child: CustomButton(
          key: Key(Strings.connect),
          text: Strings.connect,
          height: 60,
          style: 2,
          onPressed: () {
            onConnectPressed(rpcUrlController.text.trim());
          },
        ));
  }

  void onConnectPressed(String customInterxRPCUrl) {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // String customInterxRPCUrl = rpcUrlController.text;
    _storageService.setLiveRpcUrl("", "");
    _storageService.setInterxRPCUrl(customInterxRPCUrl);

    Future.delayed(const Duration(milliseconds: 500), () async {
      getNodeStatus();
    });
  }

  Widget addDescription() {
    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Row(children: <Widget>[
          Expanded(
              child: Text(
            Strings.networkDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: KiraColors.green3, fontSize: 18),
          ))
        ]));
  }

  Widget addLoginWithKeyFileButton(isBigScreen) {
    return Stack(
      children: [
        CustomButton(
          key: Key(Strings.loginWithKeyFile),
          text: Strings.loginWithKeyFile,
          width: isBigScreen ? 220 : null,
          height: 60,
          style: 2,
          onPressed: () {
            String customInterxRPCUrl = rpcUrlController.text;
            if (customInterxRPCUrl.length > 0) {
              _storageService.setInterxRPCUrl(customInterxRPCUrl);
            }
            Navigator.pushReplacementNamed(context, '/login-keyfile');
          },
        ),
        if (saifuQR == true)
          Positioned(
            top: 0,
            right: 0,
            child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50)),
                child: Container(
                  color: Color.fromRGBO(31, 23, 76, 1),
                  child: IconButton(
                    icon: Icon(
                      Icons.qr_code,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      showDialog(
                          context: context,
                          barrierColor: Colors.black54,
                          builder: (BuildContext context) {
                            return QrScannerDialog(
                              title: "Login in with Saifu",
                              qrCodeFunction: () => {
                                //TODO: Implement SAIFU Accounts (Explorer Account (public address)  with Saifu Signer on Withdrawing)
                                Navigator.popUntil(context, ModalRoute.withName('/login'))
                              },
                            );
                          });
                    },
                  ),
                )),
          )
      ],
    );
  }

  Widget addLoginWithSaifu(isBigScreen) {
    return CustomButton(
      key: Key(Strings.loginWithSaifu),
      text: Strings.loginWithSaifu,
      width: isBigScreen ? 220 : null,
      height: 60,
      style: 2,
      onPressed: () {
        // ToDo: Saifu Integration
      },
    );
  }

  Widget addLoginWithMnemonicButton(isBigScreen) {
    return CustomButton(
      key: Key(Strings.loginWithMnemonic),
      text: Strings.loginWithMnemonic,
      width: isBigScreen ? 220 : null,
      height: 60,
      style: 1,
      onPressed: () {
        String customInterxRPCUrl = rpcUrlController.text;
        if (customInterxRPCUrl.length > 0) {
          _storageService.setInterxRPCUrl(customInterxRPCUrl);
        }
        Navigator.pushReplacementNamed(context, '/login-mnemonic');
      },
    );
  }

  Widget addLoginWithExplorerButton(isBigScreen) {
    return CustomButton(
      key: Key(Strings.loginWithExplorer),
      text: Strings.loginWithExplorer,
      width: isBigScreen ? 220 : null,
      height: 60,
      style: 1,
      onPressed: () {
        _storageService.setLoginStatus(false);
        Navigator.pushReplacementNamed(context, '/account?rpc=$testedRpcUrl');
      },
    );
  }

  Widget addLoginButtonsBig() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            addLoginWithMnemonicButton(true),
            addLoginWithKeyFileButton(true),
          ]),
    );
  }

  Widget addLoadingIndicator() {
    return Container(
        margin: EdgeInsets.only(bottom: 30),
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 40,
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 30),
          padding: EdgeInsets.all(0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ));
  }

  Widget addErrorMessage() {
    return Container(
        // padding: EdgeInsets.symmetric(horizontal: 20),
        margin: EdgeInsets.only(bottom: isRpcError ? 30 : 0, top: isRpcError ? 20 : 0),
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  alignment: AlignmentDirectional(0, 0),
                  child: Text(Strings.invalidUrl,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: KiraColors.kYellowColor,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w300,
                      )),
                ),
              ],
            ),
          ],
        ));
  }

  Widget addLoginButtonsSmall() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // addLoginWithSaifu(false),
            // SizedBox(height: 30),
            addLoginWithKeyFileButton(false),
            SizedBox(height: 30),
            addLoginWithMnemonicButton(false),
            SizedBox(height: 30),
            addLoginWithExplorerButton(false),
          ]),
    );
  }

  Widget addCreateNewAccount() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Ink(
        child: Text(
          "or",
          textAlign: TextAlign.center,
          style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16),
        ),
      ),
      SizedBox(height: 20),
      CustomButton(
        key: Key(Strings.createNewAccount),
        text: Strings.createNewAccount,
        fontSize: 18,
        height: 60,
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/create-account');
        },
      )
    ]);
  }
}

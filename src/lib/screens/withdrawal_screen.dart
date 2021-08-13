import 'dart:async';
import 'dart:convert';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jdenticon/jdenticon.dart';

import 'package:kira_auth/helpers/tx_offline_signer.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/helpers/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class WithdrawalScreen extends StatefulWidget {
  @override
  _WithdrawalScreenState createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  // final _gravatarService = getIt<GravatarService>();
  final _tokenService = getIt<TokenService>();
  final _accountService = getIt<AccountService>();
  final _storageService = getIt<StorageService>();
  final _transactionService = getIt<TransactionService>();

  List<Token> tokens = [];
  List<Transaction> transactions = [];
  Account currentAccount;
  Token currentToken;
  double amountInterval = 0;
  double withdrawalAmount = 0;
  double transactionFee = 0.05;
  String feeAmount;
  Token feeToken;
  String amountError = '';
  String addressError = '';
  String transactionHash = '';
  String transactionResult = '';
  Timer timer;
  bool isNetworkHealthy = false;
  bool copied = false;
  bool loading = false;
  // Temporary for showing QR
  bool isQREnabled = false;

  FocusNode amountFocusNode;
  TextEditingController amountController;

  FocusNode addressFocusNode;
  TextEditingController addressController;

  FocusNode memoFocusNode;
  TextEditingController memoController;
  String expandedHash;
  bool initialFetched = false;
  int page = 1;
  StreamController transactionsController = StreamController.broadcast();
  int sortIndex = 0;
  bool isAscending = true;

  @override
  void initState() {
    super.initState();

    amountFocusNode = FocusNode();
    amountController = TextEditingController();
    amountController.text = withdrawalAmount.toString();
    addressFocusNode = FocusNode();
    addressController = TextEditingController();
    memoFocusNode = FocusNode();
    memoController = TextEditingController();

    getNodeStatus();
    getTokens();
    getCachedFeeAmount();
    getFeeToken();
    getWithdrawalTransactions();
  }

  @override
  void dispose() {
    amountController.dispose();
    addressController.dispose();
    memoController.dispose();
    transactionsController.close();
    super.dispose();
  }

  void getNodeStatus() async {
    final _statusService = getIt<StatusService>();
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

  void getWithdrawalTransactions() async {
    Account curAccount;
    curAccount = _accountService.currentAccount;

    if (curAccount == null) {
      curAccount = await _storageService.getCurrentAccount();
    }

    if (mounted) {
      setState(() {
        currentAccount = curAccount;
      });
    }

    if (curAccount != null) {
      List<Transaction> _transactions = _transactionService.transactions;

      if (_transactions.length == 0) {
        _transactions = await _storageService.getTransactions(curAccount.bech32Address);
      }

      if (_transactions.length == 0) {
        bool result = await _transactionService.getTransactions(curAccount.bech32Address);
        if (!result)
          setState(() {
            initialFetched = false;
          });
        _transactions = _transactionService.transactions;
      }

      if (mounted) {
        setState(() {
          transactions = _transactions.where((element) => element.action == "Withdraw").toList();
          initialFetched = true;
        });
      }
    }
  }

  void getNewTransaction(hash) async {
    Transaction tx = await _transactionService.getTransaction(hash: hash);
    tx.isNew = true;
    setState(() {
      transactions.add(tx);
    });
  }

  void getCachedFeeAmount() async {
    int cFeeAmount = await _storageService.getFeeAmount();

    setState(() {
      feeAmount = cFeeAmount.toString();
    });
  }

  void getFeeToken() async {
    Token fToken = await _storageService.getFeeToken();
    setState(() {
      feeToken = fToken;
    });
  }

  void autoPress() {
    timer = new Timer(const Duration(seconds: 2), () {
      setState(() {
        copied = false;
      });
    });
  }

  void getTokens() async {
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
          currentToken = _tokenBalance.length > 0 ? _tokenBalance[0] : null;
          amountInterval = currentToken != null && currentToken.balance != 0 ? currentToken.balance / 100 : 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _storageService = getIt<StorageService>();
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
              margin: EdgeInsets.only(top: 50, bottom: 50),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      addHeaderTitle(),
                      if (currentAccount != null) addGravatar(context),
                      if (currentToken == null) addDescription(),
                      ResponsiveWidget.isSmallScreen(context) ? addFirstLineSmall() : addFirstLineBig(),
                      ResponsiveWidget.isSmallScreen(context) ? addSecondLineSmall() : addSecondLineBig(),
                      ResponsiveWidget.isSmallScreen(context)
                          ? addWithdrawalAmountSmall(context)
                          : addWithdrawalAmountBig(context),
                      // if (loading == true) addLoadingIndicator(),
                      !initialFetched
                          ? addLoadingIndicator()
                          : transactions.isEmpty
                              ? Container(
                                  margin: EdgeInsets.only(top: 20, left: 20),
                                  child: Text("No withdrawal transactions to show",
                                      style: TextStyle(
                                          color: KiraColors.white, fontSize: 18, fontWeight: FontWeight.bold)))
                              : addTransactionsTable(),
                    ],
                  )),
            )));
  }

  Widget addHeaderTitle() {
    return Container(
        margin: EdgeInsets.only(bottom: 40),
        child: Text(
          Strings.withdrawal,
          textAlign: TextAlign.left,
          style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
        ));
  }

  Widget addTableHeader() {
    List<String> titles = ResponsiveWidget.isSmallScreen(context) ? ['Tx Hash', 'Recipient', 'Status']
        : ['Tx Hash', 'Recipient', 'Amount', 'Time', 'Status'];
    List<int> flexes = [2, 2, 1, 1, 1];

    return Container(
    padding: EdgeInsets.all(5),
    margin: EdgeInsets.only(top: 30, right: 40, bottom: 20),
    child: Row(
    children: titles
        .asMap()
        .map(
    (index, title) => MapEntry(
    index,
    Expanded(
    flex: flexes[index],
    child: InkWell(
    onTap: () => this.setState(() {
    if (sortIndex == index)
    isAscending = !isAscending;
    else {
    sortIndex = index;
    isAscending = true;
    }
    expandedHash = '';
    refreshTableSort();
    }),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: sortIndex != index
    ? [
    Text(title,
    style: TextStyle(
    color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    ]
        : [
    Text(title,
    style: TextStyle(
    color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
    SizedBox(width: 5),
    Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward,
    color: KiraColors.white),
    ],
    )))),
    )
        .values
        .toList(),
    ),
    );
    }

  Widget addDescription() {
    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Text(
          Strings.insufficientBalance,
          textAlign: TextAlign.center,
          style: TextStyle(color: KiraColors.orange3, fontSize: 18),
        ));
  }

  Widget addToken() {
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
                child: Text(Strings.tokens, style: TextStyle(color: KiraColors.kGrayColor, fontSize: 12)),
              ),
              ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                    dropdownColor: KiraColors.kPurpleColor,
                    value: currentToken != null ? currentToken.ticker : "",
                    icon: Icon(Icons.arrow_drop_down),
                    iconSize: 32,
                    underline: SizedBox(),
                    onChanged: (String ticker) {
                      setState(() {
                        currentToken = tokens.singleWhere((token) => token.ticker == ticker);
                        amountInterval = currentToken.balance / 100;
                        withdrawalAmount = 0;
                        amountController.text = withdrawalAmount.toString();
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

  Widget withdrawalAmountInput() {
    String ticker = currentToken != null ? currentToken.ticker : "";

    return AppTextField(
      labelText: Strings.withdrawalAmount,
      hintText: 'Minimum Withdrawal 0.05 ' + ticker,
      focusNode: amountFocusNode,
      controller: amountController,
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.done,
      maxLines: 1,
      autocorrect: false,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.left,
      onChanged: (String text) {
        if (text == '' || double.tryParse(text) == null) {
          setState(() {
            amountError = Strings.invalidWithdrawalAmount;
            withdrawalAmount = 0;
          });
          return;
        }

        double percent = double.tryParse(amountController.text) / amountInterval;

        if (double.tryParse(text) < 0.25 || percent > 100) {
          setState(() {
            amountError = percent > 100
                ? Strings.withdrawalAmountOutOrRange
                : "Amount to withdraw must be at least 0.05000000 " + ticker;
            withdrawalAmount = 0;
          });
          return;
        }

        setState(() {
          amountError = "";
          withdrawalAmount = double.tryParse(text);
        });
      },
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: KiraColors.white,
        fontFamily: 'NunitoSans',
      ),
    );
  }

  Widget addWithdrawalAmount() {
    int txFee = int.tryParse(feeAmount);
    String ticker = currentToken != null ? currentToken.ticker : "";
    double currentBalance = amountInterval == 0 ? 0 : withdrawalAmount / amountInterval;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'min',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KiraColors.kGrayColor,
            ),
          ),
          Text(
            'max',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KiraColors.kGrayColor,
            ),
          ),
        ],
      ),
      Container(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: KiraColors.kYellowColor.withOpacity(.7),
            inactiveTrackColor: KiraColors.kPrimaryLightColor.withOpacity(.3),
            trackHeight: 5.0,
            thumbShape: CustomSliderThumbCircle(
              thumbRadius: 15,
              min: 0,
              max: 100,
            ),
            overlayColor: KiraColors.kPrimaryColor.withOpacity(.4),
            valueIndicatorShape: PaddleSliderValueIndicatorShape(),
            valueIndicatorColor: Colors.black,
            tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 5),
            activeTickMarkColor: KiraColors.white.withOpacity(0.7),
            inactiveTickMarkColor: KiraColors.kPrimaryLightColor.withOpacity(.6),
          ),
          child: Slider(
              value: currentBalance,
              min: 0,
              max: 100,
              // divisions: 4,
              onChanged: (value) {
                setState(() {
                  withdrawalAmount = value * amountInterval;
                  amountController.text = withdrawalAmount.toStringAsFixed(0);
                  amountError = "";
                });
              }),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Transaction Fee: " + feeAmount + " " + ticker,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: KiraColors.kGrayColor)),
          Text(
            withdrawalAmount > txFee
                ? 'You Will Get: ' + (withdrawalAmount - txFee).toStringAsFixed(6) + " " + ticker
                : 'You Will Get: 0.000000 ' + ticker,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: KiraColors.kGrayColor,
            ),
          ),
        ],
      )
    ]);
  }

  Widget addWithdrawalAmountBig(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(bottom: 100),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
            ConstrainedBox(constraints: BoxConstraints(maxWidth: 500), child: addWithdrawalAmount()),
            addWithdrawButton(context, true),
          ]),
          addTransactionHashResult()
        ]));
  }

  Widget addWithdrawalAmountSmall(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(bottom: 100),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              addWithdrawalAmount(),
              addTransactionHashResult(),
              SizedBox(height: 30),
              addWithdrawButton(context, false)
            ]));
  }

  Widget addGravatar(BuildContext context) {
    final String reducedAddress =
        currentAccount.bech32Address.replaceRange(10, currentAccount.bech32Address.length - 7, '....');

    return Container(
        margin: EdgeInsets.only(bottom: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                FlutterClipboard.copy(currentAccount.bech32Address).then((value) => {
                      setState(() {
                        copied = !copied;
                      }),
                      if (copied == true) {autoPress()}
                    });
              },
              borderRadius: BorderRadius.circular(500),
              onHighlightChanged: (value) {},
              child: Container(
                width: 75,
                height: 75,
                padding: EdgeInsets.all(2),
                decoration: new BoxDecoration(
                  color: KiraColors.kPurpleColor,
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1000),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: SvgPicture.string(
                      Jdenticon.toSvg(currentAccount.bech32Address, 100, 10),
                      fit: BoxFit.contain,
                      height: 70,
                      width: 70,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 20,
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeIn,
              child: InkWell(
                onTap: () {
                  copyText(currentAccount.bech32Address);
                  showToast(Strings.publicAddressCopied);
                },
                child: Text(copied ? Strings.copied : reducedAddress,
                    style: TextStyle(
                      color: copied ? KiraColors.green3 : KiraColors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      fontFamily: 'NunitoSans',
                      letterSpacing: 1,
                    )),
              ),
            ),
          ],
        ));
  }

  showTransactionStatus(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text(
        Strings.cancel,
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
            width: 450,
            child: CustomDialog(
              contentWidgets: [
                Text(
                  Strings.txDetails,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, color: KiraColors.kPurpleColor, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 30),
                Text(
                  "Status: ",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: KiraColors.blue1, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "$transactionResult",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: KiraColors.black),
                ),
                SizedBox(height: 12),
                Text(
                  "TX Hash : ",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: KiraColors.blue1, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "0x" + transactionHash.toLowerCase(),
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: KiraColors.black),
                ),
                SizedBox(height: 32),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[cancelButton]),
              ],
            ));
      },
    );
  }

  Widget addWithdrawButton(BuildContext context, bool isBig) {
    String denomination = currentToken != null ? currentToken.denomination : "";
    return Stack(
      children: [
        CustomButton(
          key: Key(Strings.withdraw),
          text: Strings.withdraw,
          width: isBig == true ? 200 : null,
          height: isBig == true ? 50.0 : 60,
          fontSize: 18,
          style: 2,
          onPressed: () async {
            if (withdrawalAmount == 0) {
              setState(() {
                amountError = Strings.invalidWithdrawalAmount;
              });
              return;
            }

            if (addressController.text == '') {
              setState(() {
                addressError = Strings.invalidWithdrawalAddress;
              });
              return;
            }

            setState(() {
              transactionResult = Strings.transactionSubmitted;
              loading = true;
            });

            final message = MsgSend(
                fromAddress: currentAccount.bech32Address,
                toAddress: addressController.text.trim(),
                amount: [StdCoin(denom: denomination, amount: withdrawalAmount.toString())]);

            final feeV = StdCoin(amount: feeAmount, denom: feeToken.denomination);
            final fee = StdFee(gas: '999999', amount: [feeV]);

            // Structure and organize the transcation
            final stdTx = TransactionBuilder.buildStdTx([message], stdFee: fee, memo: memoController.text);

            // Sign the transaction
            final signedStdTx = await TransactionSigner.signStdTx(currentAccount, stdTx);

            // Broadcast signed transaction
            final result = await TransactionSender.broadcastStdTx(account: currentAccount, stdTx: signedStdTx);

            if (result == false) {
              setState(() {
                transactionResult = Strings.invalidRequest;
                transactionHash = "";
                loading = false;
              });
            } else if (result['height'] == "0") {
              // print("Tx send error: " + result['check_tx']['log']);
              if (result['check_tx']['log'].toString().contains("invalid")) {
                setState(() {
                  transactionResult = Strings.invalidRequest;
                  transactionHash = "";
                  loading = false;
                });
              }
            } else {
              // print("Tx send successfully. Hash: 0x" + result['hash']);
              setState(() {
                transactionResult = Strings.transactionSuccess;
                transactionHash = result['hash'];
                amountController.text = "";
                addressController.text = "";
                memoController.text = "";
                loading = false;
              });
              getNewTransaction("0x" + result['hash']);
            }

            showTransactionStatus(context);
          },
        ),
        if (isQREnabled == true)
          Positioned(
              top: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50), bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
                child: Container(
                    color: Color.fromRGBO(31, 23, 76, 1),
                    child: IconButton(
                      icon: Icon(
                        Icons.qr_code,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () async {
                        String denomination = currentToken != null ? currentToken.denomination : "";
                        if (withdrawalAmount == 0) {
                          setState(() {
                            amountError = Strings.invalidWithdrawalAmount;
                          });
                          return;
                        }

                        if (addressController.text == '') {
                          setState(() {
                            addressError = Strings.invalidWithdrawalAddress;
                          });
                          return;
                        }

                        setState(() {
                          transactionResult = Strings.transactionSubmitted;
                          loading = true;
                        });

                        final message = MsgSend(
                            fromAddress: currentAccount.bech32Address,
                            toAddress: addressController.text.trim(),
                            amount: [StdCoin(denom: denomination, amount: withdrawalAmount.toString())]);

                        final feeV = StdCoin(amount: feeAmount, denom: feeToken.denomination);
                        final fee = StdFee(gas: '200000', amount: [feeV]);

                        final stdTx = TransactionBuilder.buildStdTx([message], stdFee: fee, memo: memoController.text);

                        final Map<String, dynamic> sortedJson =
                            await TransactionOfflineSigner.getOnlineInformation(currentAccount, stdTx);
                        var qrData = json.encode(sortedJson);
                        dynamic processTranscation = await showDialog(
                            useRootNavigator: false,
                            context: context,
                            barrierColor: Colors.black.withOpacity(0),
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return SignatureDialog(
                                current: currentAccount,
                                message: message,
                                feeV: feeV,
                                fee: fee,
                                stdTx: stdTx,
                                sortedJson: qrData,
                              );
                            });

                        String data = "";
                        var dataset = [];
                        // Decode the information
                        for (var i = 0; i < processTranscation.length; i++) {
                          //var base64Str = base64.decode(widget.qrData[i]);
                          //var bytes = utf8.decode(base64Str);
                          var decodeJson = json.decode(processTranscation[i]);
                          dataset.add(decodeJson);
                        }
                        // Sort into corrrect page order
                        dataset.sort((m1, m2) {
                          return m1["page"].compareTo(m2["page"]);
                        });

                        // Iterate sorted information to collect the data to show

                        for (var i = 0; i < dataset.length; i++) {
                          String dataValue = utf8.decode(base64.decode(dataset[i]['data']));

                          data = data + dataValue;
                        }

                        //var base64Str = base64.decode(widget.qrData[i]);
                        //var bytes = utf8.decode(base64Str);

                        var signature = json.decode(data);

                        // Structures and creates the transcation structure
                        StdPublicKey stdPublicKey =
                            StdPublicKey(key: signature['publicKey']['value'], type: signature['publicKey']['type']);
                        Map<String, dynamic> map = {'signature': signature['signature'], 'publicKey': stdPublicKey};
                        final signOfflineStdTx =
                            await TransactionOfflineSigner.signOfflineStdTx(currentAccount, stdTx, map);
                        final result =
                            await TransactionSender.broadcastStdTx(account: currentAccount, stdTx: signOfflineStdTx);

                        if (result == false) {
                          setState(() {
                            transactionResult = Strings.invalidRequest;
                            transactionHash = "";
                            loading = false;
                          });
                        } else if (result['height'] == "0") {
                          // print("Tx send error: " + result['check_tx']['log']);
                          if (result['check_tx']['log'].toString().contains("invalid")) {
                            setState(() {
                              transactionResult = Strings.invalidRequest;
                              transactionHash = "";
                            });
                          }
                        } else {
                          // print("Tx send successfully. Hash: 0x" + result['hash']);
                          setState(() {
                            transactionResult = Strings.transactionSuccess;
                            transactionHash = result['hash'];
                            amountController.text = "";
                            addressController.text = "";
                            memoController.text = "";
                          });
                          getNewTransaction("0x" + result['hash']);
                        }

                        showTransactionStatus(context);
                      },
                    )),
              )),
      ],
    );
  }

  Widget addLoadingIndicator() {
    return Container(
        alignment: Alignment.center,
        child: Container(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ));
  }

  Widget addTransactionsTable() {
    return Container(
        margin: EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TransactionsTable(
              page: page,
              setPage: (newPage) => this.setState(() {
                page = newPage;
              }),
              isDeposit: false,
              transactions: transactions,
              expandedHash: expandedHash,
              onTapRow: (hash) => this.setState(() {
                expandedHash = hash;
              }),
              controller: transactionsController,
            )
          ],
        ));
  }

  Widget addTransactionHashResult() {
    return Container(
        margin: EdgeInsets.only(top: 50),
        child: Column(
          children: [
            // Column(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   children: [
            //     if (transactionResult != '')
            //       Container(
            //         alignment: AlignmentDirectional(0, 0),
            //         margin: EdgeInsets.only(bottom: 10),
            //         child: Text(transactionResult,
            //             style: TextStyle(
            //               fontSize: 16.0,
            //               color: transactionResult.contains("success") ? KiraColors.green3 : KiraColors.kYellowColor,
            //               fontFamily: 'NunitoSans',
            //               fontWeight: FontWeight.w600,
            //             )),
            //       ),
            //     if (transactionHash != '')
            //       Container(
            //         alignment: AlignmentDirectional(0, 0),
            //         margin: EdgeInsets.only(bottom: 10),
            //         child: Text("0x" + transactionHash.toLowerCase(),
            //             style: TextStyle(
            //               fontSize: 15.0,
            //               color: transactionResult.contains("success") ? KiraColors.green3 : KiraColors.kYellowColor,
            //               fontFamily: 'NunitoSans',
            //               fontWeight: FontWeight.w600,
            //             )),
            //       ),
            //   ],
            // ),
            if (loading == true) addLoadingIndicator(),
          ],
        ));
  }

  Widget addWithdrawalAddress() {
    return Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
      AppTextField(
        hintText: Strings.withdrawalAddress,
        labelText: Strings.withdrawalAddress,
        focusNode: addressFocusNode,
        controller: addressController,
        textInputAction: TextInputAction.done,
        maxLines: 1,
        autocorrect: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
        onChanged: (String text) {
          if (text.startsWith('kira') == false) {
            setState(() {
              addressError = Strings.invalidWithdrawalAddress;
            });
          } else {
            setState(() {
              addressError = "";
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
      if (addressError != '') SizedBox(height: 10),
      if (addressError != '')
        Text(
          addressError,
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: KiraColors.kYellowColor.withOpacity(0.8),
          ),
        ),
    ]);
  }

  Widget addFirstLineSmall() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            addToken(),
            SizedBox(height: 30),
            addWithdrawalAddress(),
          ]),
    );
  }

  Widget addFirstLineBig() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: addToken(), flex: 1),
            SizedBox(width: 60),
            Expanded(child: addWithdrawalAddress(), flex: 1),
          ]),
    );
  }

  Widget addMemo() {
    return AppTextField(
      hintText: Strings.memo,
      labelText: Strings.memo,
      focusNode: memoFocusNode,
      controller: memoController,
      textInputAction: TextInputAction.next,
      maxLines: null,
      autocorrect: false,
      keyboardType: TextInputType.multiline,
      textAlign: TextAlign.left,
      onChanged: (String text) {
        if (text == '') {
          setState(() {
            addressError = "";
          });
        }
      },
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: KiraColors.white,
        fontFamily: 'NunitoSans',
      ),
    );
  }

  Widget addWithdrawalAmountInput() {
    String ticker = currentToken != null ? currentToken.ticker : "";

    return Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
      withdrawalAmountInput(),
      SizedBox(height: 10),
      Text(
        'Available Balance ' + (amountInterval * 100).toStringAsFixed(6) + " " + ticker,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: KiraColors.white,
        ),
      ),
      if (amountError != '') SizedBox(height: 10),
      if (amountError != '')
        Text(
          amountError,
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: KiraColors.kYellowColor.withOpacity(0.8),
          ),
        ),
    ]);
  }

  Widget addSecondLineSmall() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            addWithdrawalAmountInput(),
            SizedBox(height: 30),
            addMemo(),
          ]),
    );
  }

  Widget addSecondLineBig() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: addWithdrawalAmountInput(), flex: 1),
            SizedBox(width: 60),
            Expanded(child: addMemo(), flex: 1),
          ]),
    );
  }

  refreshTableSort() {
    if (sortIndex == 0) {
      transactions.sort((a, b) => isAscending ? a.hash.compareTo(b.hash) : b.hash.compareTo(a.hash));
    } else if (sortIndex == 1) {
      transactions.sort((a, b) => isAscending ? a.recipient.compareTo(b.recipient) : b.sender.compareTo(a.recipient));
    } else if (sortIndex == 2) {
      if (ResponsiveWidget.isSmallScreen(context))
        transactions.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
      else
        transactions.sort((a, b) => isAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount));
    } else if (sortIndex == 3) {
      transactions.sort((a, b) => isAscending ? a.time.compareTo(b.time) : b.time.compareTo(a.time));
    } else {
      transactions.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
    }
    transactionsController.add(null);
  }
}

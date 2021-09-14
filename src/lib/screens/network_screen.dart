import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class NetworkScreen extends StatefulWidget {
  @override
  _NetworkScreenState createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final _networkService = getIt<NetworkService>();

  List<Validator> validators = [];
  String query = "";
  bool moreLoading = false;
  Account currentAccount;
  bool isFiltering = false;

  List<String> favoriteValidators = [];
  int expandedTop = -1;
  int sortIndex = 0;
  bool isAscending = true;
  bool isNetworkHealthy = false;
  int page = 1;
  StreamController validatorController = StreamController.broadcast();

  bool isLoggedIn = false;
  String customInterxRPCUrl = "";
  List<String> networkIds = [Strings.customNetwork];
  String networkId = Strings.customNetwork;
  Timer timer;

  @override
  void initState() {
    super.initState();

    final _storageService = getIt<StorageService>();
    _storageService.setTopbarIndex(3);

    var uri = Uri.dataFromString(html.window.location.href); //converts string to a uri
    Map<String, String> params = uri.queryParameters; // query parameters automatically populated

    if (params.containsKey("rpc")) {
      customInterxRPCUrl = params['rpc'];
      setState(() {
        isNetworkHealthy = false;
      });
      _storageService.setInterxRPCUrl(customInterxRPCUrl);
    } else {
      _storageService.getLoginStatus().then((isLoggedIn) {
        if (isLoggedIn) {
          setState(() {
            _storageService.checkPasswordExpired().then((success) {
              if (success) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            });
          });
        }
      });
    }

    getNodeStatus();
    getValidators();
    getCurrentAccount();

    timer = Timer.periodic(Duration(minutes: 2), (timer) {
      getValidators();
    });
  }

  getCurrentAccount() async {
    final _accountService = getIt<AccountService>();
    final _storageService = getIt<StorageService>();
    Account curAccount = _accountService.currentAccount;

    if (_accountService.currentAccount == null) {
      curAccount = await _storageService.getCurrentAccount();
    }

    if (mounted) {
      setState(() {
        currentAccount = curAccount;
      });
    }
  }

  void getValidators() async {
    setState(() {
      moreLoading = true;
    });
    await _networkService.getValidators();
    if (mounted) {
      setState(() {
        moreLoading = false;
        if (isLoggedIn) favoriteValidators = BlocProvider.of<ValidatorBloc>(context).state.favoriteValidators;
        var temp = _networkService.validators;
        temp.forEach((element) {
          element.isFavorite = isLoggedIn || favoriteValidators.contains(element.address);
        });
        if (sortIndex == 0) {
          temp.sort((a, b) => isAscending ? a.top.compareTo(b.top) : b.top.compareTo(a.top));
        } else if (sortIndex == 2) {
          temp.sort((a, b) => isAscending ? a.moniker.compareTo(b.moniker) : b.moniker.compareTo(a.moniker));
        } else if (sortIndex == 3) {
          temp.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
        } else if (sortIndex == 4) {
          temp.sort((a, b) => !isAscending
              ? a.isFavorite.toString().compareTo(b.isFavorite.toString())
              : b.isFavorite.toString().compareTo(a.isFavorite.toString()));
        }
        validators.clear();
        validators.addAll(temp);

        var uri = Uri.dataFromString(html.window.location.href);
        Map<String, String> params = uri.queryParameters;

        var keyword = query;
        if (params.containsKey("info")) keyword = params['info'].toLowerCase();

        validatorController.add(keyword);
      });
    }
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
        if (nodeInfo != null && nodeInfo.network.isNotEmpty) {
          isNetworkHealthy = networkHealth;
          if (this.customInterxRPCUrl != "") {
            setState(() {
              if (!networkIds.contains(nodeInfo.network)) {
                networkIds.add(nodeInfo.network);
              }
              networkId = nodeInfo.network;
              isNetworkHealthy = networkHealth;
            });
            this.customInterxRPCUrl = "";
          }
        } else {
          isNetworkHealthy = false;
        }
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: HeaderWrapper(
          isNetworkHealthy: isNetworkHealthy,
          childWidget: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(vertical: ResponsiveWidget.isSmallScreen(context) ? 10 : 50),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    addHeaderTitle(),
                    isFiltering ? addSearchInput() : Container(),
                    addTableHeader(),
                    moreLoading
                        ? addLoadingIndicator()
                        : validators.isEmpty
                            ? Container(
                                margin: EdgeInsets.only(top: 20, left: 20),
                                child: Text("No validators to show",
                                    style: TextStyle(
                                        color: KiraColors.white, fontSize: 18, fontWeight: FontWeight.bold)))
                            : addValidatorsTable(),
                  ],
                ),
              ))));
  }

  Widget addLoadingIndicator() {
    return Container(
        alignment: Alignment.center,
        child: Container(
          width: 20,
          height: 20,
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 30),
          padding: EdgeInsets.all(0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ));
  }

  Widget addHeaderTitle() {
    return Container(
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ResponsiveWidget.isSmallScreen(context) ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    Strings.validators,
                    textAlign: TextAlign.left,
                    style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
                  )),
              SizedBox(height: 10),
              Padding(padding: EdgeInsets.only(left: 30),
                child: Row(children: <Widget>[
                  InkWell(
                      onTap: () => Navigator.pushReplacementNamed(context, '/blocks'),
                      child: Icon(Icons.swap_horiz, color: KiraColors.white.withOpacity(0.8))),
                  SizedBox(width: 10),
                  InkWell(
                    onTap: () => Navigator.pushReplacementNamed(context, '/blocks'),
                    child: Container(
                        child: Text(
                          Strings.blocks,
                          textAlign: TextAlign.left,
                          style: TextStyle(color: KiraColors.white, fontSize: 20, fontWeight: FontWeight.w900),
                        )),
                  )],
                )),
              SizedBox(height:30)
            ],
          ) : Row(
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(bottom: 50),
                  child: Text(
                    Strings.validators,
                    textAlign: TextAlign.left,
                    style: TextStyle(color: KiraColors.white, fontSize: 30, fontWeight: FontWeight.w900),
                  )),
              SizedBox(width: 30),
              InkWell(
                  onTap: () => Navigator.pushReplacementNamed(context, '/blocks'),
                  child: Icon(Icons.swap_horiz, color: KiraColors.white.withOpacity(0.8))),
              SizedBox(width: 10),
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, '/blocks'),
                child: Container(
                    child: Text(
                  Strings.blocks,
                  textAlign: TextAlign.left,
                  style: TextStyle(color: KiraColors.white, fontSize: 20, fontWeight: FontWeight.w900),
                )),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(right: 20),
            child: isFiltering
                ? InkWell(
                onTap: () {
                  this.setState(() {
                    isFiltering = false;
                    expandedTop = -1;
                  });
                },
                child: Icon(Icons.close, color: KiraColors.white, size: 30))
                : Tooltip(
              message: Strings.validatorQuery,
              waitDuration: Duration(milliseconds: 500),
              decoration: BoxDecoration(color: KiraColors.purple1, borderRadius: BorderRadius.circular(4)),
              verticalOffset: 20,
              preferBelow: ResponsiveWidget.isSmallScreen(context),
              margin: EdgeInsets.only(
                  right: ResponsiveWidget.isSmallScreen(context)
                      ? 20
                      : ResponsiveWidget.isMediumScreen(context)
                      ? 50
                      : 110),
              textStyle: TextStyle(color: KiraColors.white.withOpacity(0.8)),
              child: InkWell(
                onTap: () {
                  this.setState(() {
                    isFiltering = true;
                    expandedTop = -1;
                  });
                },
                child: Icon(Icons.search, color: KiraColors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget addSearchInput() {
    return Container(
      width: 500,
      child: AppTextField(
        hintText: Strings.validatorQuery,
        labelText: Strings.search,
        textInputAction: TextInputAction.search,
        maxLines: 1,
        autocorrect: false,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
        onChanged: (String newText) {
          this.setState(() {
            query = newText.toLowerCase();
            expandedTop = -1;
            validatorController.add(query);
          });
        },
        padding: EdgeInsets.only(bottom: 15),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
          color: KiraColors.white,
          fontFamily: 'NunitoSans',
        ),
        topMargin: 10,
      ),
    );
  }

  Widget addTableHeader() {
    return Container(
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 20, right: 40, bottom: 10),
      child: Row(
        children: [
          Expanded(
              flex: ResponsiveWidget.isSmallScreen(context) ? 3 : 2,
              child: InkWell(
                  onTap: () => this.setState(() {
                        if (sortIndex == 3)
                          isAscending = !isAscending;
                        else {
                          sortIndex = 3;
                          isAscending = true;
                        }
                        expandedTop = -1;
                        refreshTableSort();
                      }),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sortIndex != 3
                          ? [
                              Text("Status",
                                  style: TextStyle(
                                      color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            ]
                          : [
                              Text("Status",
                                  style: TextStyle(
                                      color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(width: 5),
                              Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: KiraColors.white),
                            ]))),
          Expanded(
              flex: ResponsiveWidget.isSmallScreen(context) ? 3 : 2,
              child: InkWell(
                  onTap: () => this.setState(() {
                        if (sortIndex == 0)
                          isAscending = !isAscending;
                        else {
                          sortIndex = 0;
                          isAscending = true;
                        }
                        expandedTop = -1;
                        refreshTableSort();
                      }),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sortIndex != 0
                          ? [
                              Text("Top",
                                  style: TextStyle(
                                      color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            ]
                          : [
                              Text("Top",
                                  style: TextStyle(
                                      color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(width: 5),
                              Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: KiraColors.white),
                            ]))),
          Expanded(
              flex: ResponsiveWidget.isSmallScreen(context) ? 6 : 3,
              child: InkWell(
                  onTap: () => this.setState(() {
                        if (sortIndex == 2)
                          isAscending = !isAscending;
                        else {
                          sortIndex = 2;
                          isAscending = true;
                        }
                        expandedTop = -1;
                        refreshTableSort();
                      }),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sortIndex != 2
                          ? [
                              Text("Moniker",
                                  style: TextStyle(
                                      color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            ]
                          : [
                              Text("Moniker",
                                  style: TextStyle(
                                      color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(width: 5),
                              Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: KiraColors.white),
                            ]))),
          ResponsiveWidget.isSmallScreen(context) ? Container() :
          Expanded(
              flex: 9,
              child: Text("Validator Address",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold))),
          !isLoggedIn
              ? Container()
              : Expanded(
                  flex: ResponsiveWidget.isSmallScreen(context) ? 3 : 2,
                  child: InkWell(
                      onTap: () => this.setState(() {
                            if (sortIndex == 4)
                              isAscending = !isAscending;
                            else {
                              sortIndex = 4;
                              isAscending = true;
                            }
                            expandedTop = -1;
                            refreshTableSort();
                          }),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: sortIndex != 4
                              ? [
                                  Text("Favorite",
                                      style: TextStyle(
                                          color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                                ]
                              : [
                                  Text("Favorite",
                                      style: TextStyle(
                                          color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 5),
                                  Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: KiraColors.white),
                                ]))),
        ],
      ),
    );
  }

  Widget addValidatorsTable() {
    return Container(
        margin: EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValidatorsTable(
              isLoggedIn: isLoggedIn,
              page: page,
              setPage: (newPage) => this.setState(() {
                page = newPage;
              }),
              validators: validators,
              expandedTop: expandedTop,
              onChangeLikes: (top) {
                var index = validators.indexWhere((element) => element.top == top);
                if (index >= 0) {
                  BlocProvider.of<ValidatorBloc>(context)
                      .add(ToggleFavoriteAddress(validators[index].address, currentAccount.hexAddress));
                  this.setState(() {
                    validators[index].isFavorite = !validators[index].isFavorite;
                  });
                }
              },
              controller: validatorController,
              onTapRow: (top) => this.setState(() {
                expandedTop = top;
              }),
            ),
          ],
        ));
  }

  void refreshTableSort() {
    if (sortIndex == 0) {
      validators.sort((a, b) => isAscending ? a.top.compareTo(b.top) : b.top.compareTo(a.top));
    } else if (sortIndex == 2) {
      validators.sort((a, b) => isAscending ? a.moniker.compareTo(b.moniker) : b.moniker.compareTo(a.moniker));
    } else if (sortIndex == 3) {
      validators.sort((a, b) => isAscending ? a.status.compareTo(b.status) : b.status.compareTo(a.status));
    } else if (sortIndex == 4) {
      validators.sort((a, b) => !isAscending
          ? a.isFavorite.toString().compareTo(b.isFavorite.toString())
          : b.isFavorite.toString().compareTo(a.isFavorite.toString()));
    }
    validatorController.add(null);
  }
}

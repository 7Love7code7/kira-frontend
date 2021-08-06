import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class TopBarContents extends StatefulWidget {
  final double opacity;
  final bool _loggedIn;
  final bool _isNetworkHealthy;
  final bool _display;

  TopBarContents(this.opacity, this._loggedIn, this._isNetworkHealthy, this._display);

  @override
  _TopBarContentsState createState() => _TopBarContentsState();
}

class _TopBarContentsState extends State<TopBarContents> {
  final _storageService = getIt<StorageService>();

  final List _isHovering = [false, false, false, false, false, false, false, false, false, false];
  final List _notSearched = [true, false, false, true, true, true];

  bool _isProcessing = false;
  int selectedIndex = 0;
  String rpcUrl;
  String navParam = "";

  @override
  void initState() {
    super.initState();
    getNodeStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getNodeStatus() async {
    String lastSearchedAccount = await _storageService.getLastSearchedAccount();
    if (lastSearchedAccount.isNotEmpty) navParam = "&addr=" + lastSearchedAccount;
    var topbarIndex = await _storageService.getTopbarIndex();

    if (mounted) {
      setState(() {
        selectedIndex = topbarIndex;
      });
    }
  }

  List<Widget> navItems(String nodeAddress) {
    List<Widget> items = [];

    for (int i = 0; i < 6; i++) {
      if (!widget._loggedIn ? _notSearched[i] : true)
        items.add(Container(
          margin: EdgeInsets.only(left: 30, right: 30, top: 10),
          child: InkWell(
            onHover: (value) {
              setState(() {
                value ? _isHovering[i] = true : _isHovering[i] = false;
              });
            },
            onTap: () {
              _storageService.setTopbarIndex(i);
              switch (i) {
                case 0: // Account
                  Navigator.pushReplacementNamed(
                      context, '/account' + (!widget._loggedIn ? '?rpc=${nodeAddress}$navParam' : ''));
                  break;
                case 1: // Deposit
                  Navigator.pushReplacementNamed(context, '/deposit');
                  break;
                case 2: // Withdrawal
                  Navigator.pushReplacementNamed(context, '/withdraw');
                  break;
                case 3: // Network
                  Navigator.pushReplacementNamed(
                      context, '/network' + (!widget._loggedIn ? '?rpc=${nodeAddress}' : ''));
                  break;
                case 4: // Proposals
                  Navigator.pushReplacementNamed(
                      context, '/proposals' + (!widget._loggedIn ? '?rpc=${nodeAddress}' : ''));
                  break;
                case 5: // Settings
                  Navigator.pushReplacementNamed(context, widget._loggedIn ? '/settings' : '/login');
                  break;
              }
            },
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    !widget._loggedIn ? Strings.navItemTitlesExplorer[i] : Strings.navItemTitles[i],
                    style: TextStyle(
                      fontSize: 15,
                      color: _isHovering[i] || i == selectedIndex ? KiraColors.kYellowColor : KiraColors.kGrayColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Visibility(
                    maintainAnimation: true,
                    maintainState: true,
                    maintainSize: true,
                    visible: _isHovering[i],
                    child: Container(
                      alignment: Alignment.centerLeft,
                      height: 3,
                      width: 30,
                      color: KiraColors.kYellowColor,
                    ),
                  ),
                ]),
          ),
        ));
    }

    return items;
  }

  showAvailableNetworks(BuildContext context, String networkId, String nodeAddress) {
    Widget disconnectButton = TextButton(
      child: Text(
        Strings.disconnect,
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      onPressed: () {
        final _statusService = getIt<StatusService>();
        _statusService.disconnect();
        _storageService.setNetworkHealth(false);
        _storageService.setNodeStatusData("");
        _storageService.removePassword();
        _storageService.setInterxRPCUrl("");
        _storageService.setLiveRpcUrl("", "");
        BlocProvider.of<NetworkBloc>(context).add(SetNetworkInfo(Strings.customNetwork, ""));
        Navigator.pushReplacementNamed(context, '/login');
      },
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
            width: 250,
            child: CustomDialog(
              contentWidgets: [
                Text(
                  Strings.networkInformation,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, color: KiraColors.kPurpleColor, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 22),
                Row(children: [
                  Text(
                    "Connected Network : ",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: KiraColors.blue1, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    networkId,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: KiraColors.black),
                  ),
                ]),
                SizedBox(height: 12),
                Row(children: [
                  Text(
                    "RPC Address : ",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: KiraColors.blue1, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    nodeAddress,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: KiraColors.black),
                  ),
                ]),
                SizedBox(height: 12),
                Row(children: [
                  Text(
                    "Network Status : ",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: KiraColors.blue1, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget._isNetworkHealthy == true ? "Healthy" : "Unhealthy",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: KiraColors.black),
                  ),
                ]),
                SizedBox(height: 32),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[disconnectButton]),
              ],
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var networkStatusColor = widget._isNetworkHealthy == true ? KiraColors.green3 : KiraColors.orange3;
    var networkId = BlocProvider.of<NetworkBloc>(context).state.networkId;
    var nodeAddress = BlocProvider.of<NetworkBloc>(context).state.nodeAddress;
    networkId = networkId == null ? Strings.noAvailableNetworks : networkId;

    return PreferredSize(
      preferredSize: Size(screenSize.width, 1000),
      child: Container(
        height: 120,
        alignment: AlignmentDirectional.center,
        margin: const EdgeInsets.all(0),
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                InkWell(
                    onTap: () => Navigator.pushReplacementNamed(context, '/'),
                    child: Image(image: AssetImage(Strings.logoImage), width: 60, height: 60)),
                SizedBox(width: 5),
                Text(
                  Strings.kiraNetwork,
                  style: TextStyle(
                    color: KiraColors.white,
                    fontSize: 18,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            widget._display == true
                ? Expanded(
                    child: Center(
                        child: Wrap(
                      children: navItems(nodeAddress),
                    )),
                  )
                : Expanded(child: SizedBox(width: 500)),
            SizedBox(
              width: screenSize.width / 50,
            ),
            InkWell(
              // onTap: widget._isNetworkHealthy == null ? () {} : null,
              onTap: () {
                if (networkId != Strings.noAvailableNetworks && nodeAddress.isNotEmpty)
                  showAvailableNetworks(context, networkId, nodeAddress);
              },
              child: Row(
                children: [
                  Text(
                    networkId == null ? Strings.noAvailableNetworks : networkId,
                    style: TextStyle(
                        fontFamily: 'Mulish', color: Colors.white.withOpacity(0.5), fontSize: 15, letterSpacing: 1),
                  ),
                  SizedBox(width: 12),
                  Container(
                      decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        border: new Border.all(
                          color: networkStatusColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        child: Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.circle,
                            size: 15.0,
                            color: networkStatusColor,
                          ),
                        ),
                      )),
                  SizedBox(
                    height: 25,
                  ),
                ],
              ),
            ),
            InkWell(
              onHover: (value) {
                setState(() {
                  value ? _isHovering[3] = true : _isHovering[3] = false;
                });
              },
              onTap: widget._loggedIn == false ? () {} : null,
              child: Row(
                children: [
                  SizedBox(width: 35),
                  if (widget._loggedIn == true)
                    ElevatedButton(
                      // color: KiraColors.transparent,
                      // hoverColor: KiraColors.purple1,
                      // highlightColor: KiraColors.purple2,
                      onPressed: () {
                        if (widget._loggedIn == true) {
                          final _accountService = getIt<AccountService>();
                          _accountService.setCurrentAccount(null);
                        } else {
                          final _statusService = getIt<StatusService>();
                          _statusService.disconnect();
                          _storageService.setNetworkHealth(false);
                          _storageService.setNodeStatusData("");
                          _storageService.removePassword();
                          _storageService.setInterxRPCUrl("");
                          _storageService.setLiveRpcUrl("", "");
                          BlocProvider.of<NetworkBloc>(context).add(SetNetworkInfo(Strings.customNetwork, ""));
                        }
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      // shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(5), side: BorderSide(color: KiraColors.buttonBorder)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                        child: _isProcessing
                            ? CircularProgressIndicator()
                            : Text(
                                widget._loggedIn == true ? Strings.logout : Strings.disconnect,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

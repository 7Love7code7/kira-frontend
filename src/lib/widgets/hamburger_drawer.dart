import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/blocs/export.dart';
import 'package:kira_auth/service_manager.dart';
import 'package:kira_auth/services/export.dart';

class HamburgerDrawer extends StatefulWidget {
  HamburgerDrawer({
    Key key,
  }) : super(key: key);

  @override
  _HamburgerDrawerState createState() => _HamburgerDrawerState();
}

class _HamburgerDrawerState extends State<HamburgerDrawer> {
  final List _isHovering = [false, false, false, false, false, false];

  String navParam = "";
  bool isLoggedIn = false;
  String networkId = Strings.noAvailableNetworks;
  String rpcUrl;
  bool isNetworkHealthy;

  final _storageService = getIt<StorageService>();

  @override
  void initState() {
    super.initState();

    getNodeStatus();
    _storageService.getLoginStatus().then((loggedIn) => this.setState(() {
          isLoggedIn = loggedIn;
        }));
  }

  void getNodeStatus() async {
    var apiUrl = await _storageService.getLiveRpcUrl();
    bool networkHealth = await _storageService.getNetworkHealth();
    NodeInfo nodeInfo = await _storageService.getNodeStatusData("NODE_INFO");

    if (nodeInfo == null) {
      final _storageService = getIt<StorageService>();
      nodeInfo = await _storageService.getNodeStatusData("NODE_INFO");
    }

    if (mounted) {
      setState(() {
        if (nodeInfo != null && nodeInfo.network.isNotEmpty) {
          networkId = nodeInfo.network;
          rpcUrl = getIPOnly(apiUrl[0]);
          isNetworkHealthy = networkHealth;
        } else {
          isNetworkHealthy = false;
        }
      });
    }

    setState(() {});

    String lastSearchedAccount = await _storageService.getLastSearchedAccount();
    if (lastSearchedAccount.isNotEmpty) navParam = "&addr=" + lastSearchedAccount;
  }

  List<Widget> navItems() {
    List<Widget> items = [];

    for (int i = 0; i < 6; i++) {
      if (!isLoggedIn && (i == 1 || i == 2)) continue;
      items.add(
        InkWell(
          onHover: (value) {
            setState(() {
              value ? _isHovering[i] = true : _isHovering[i] = false;
            });
          },
          onTap: () {
            switch (i) {
              case 0: // account
                Navigator.pushReplacementNamed(context, '/account' + (!isLoggedIn ? '?rpc=${rpcUrl}$navParam' : ''));
                break;
              case 1: // Deposit
                Navigator.pushReplacementNamed(context, '/deposit');
                break;
              case 2: // Withdrawal
                Navigator.pushReplacementNamed(context, '/withdraw');
                break;
              case 3: // Network
                Navigator.pushReplacementNamed(context, '/network' + (!isLoggedIn ? '?rpc=${rpcUrl}' : ''));
                break;
              case 4: // Proposals
                Navigator.pushReplacementNamed(context, '/proposals' + (!isLoggedIn ? '?rpc=${rpcUrl}' : ''));
                break;
              case 5: // Settings
                Navigator.pushReplacementNamed(context, isLoggedIn ? '/settings' : '/login');
                break;
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLoggedIn ? Strings.navItemTitles[i] : Strings.navItemTitlesExplorer[i],
                style: TextStyle(
                  fontSize: 18,
                  color: _isHovering[i] ? KiraColors.white : KiraColors.kGrayColor,
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
              SizedBox(height: 18),
            ],
          ),
        ),
      );
    }

    if (isLoggedIn)
      items.add(ElevatedButton(
        onPressed: () {
          _storageService.removePassword();
          Navigator.pushReplacementNamed(context, '/login');
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Text(
            Strings.logout,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ));

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
                SizedBox(height: 30),
                Text(
                  "Connected Network : ",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: KiraColors.blue1, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "${networkId[0].toUpperCase()}${networkId.substring(1)}",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: KiraColors.black),
                ),
                SizedBox(height: 12),
                Text(
                  "RPC Address : ",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: KiraColors.blue1, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  nodeAddress,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 18, color: KiraColors.black),
                ),
                SizedBox(height: 12),
                Text(
                  "Network Status : ",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: KiraColors.blue1, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  isNetworkHealthy == true ? "Healthy" : "Unhealthy",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: KiraColors.black),
                ),
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
    var networkStatusColor = isNetworkHealthy == true ? KiraColors.green3 : KiraColors.orange3;

    return Drawer(
      elevation: 1,
      child: Container(
        color: Color.fromARGB(255, 60, 20, 100),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
                child: Image(
              image: AssetImage(Strings.logoImage),
              width: 90,
              height: 90,
            )),
            Container(
              padding: const EdgeInsets.all(15.0),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                Strings.kiraNetwork,
                textAlign: TextAlign.center,
                style: TextStyle(color: KiraColors.white, fontSize: 24),
              ),
            ),
            ConstrainedBox(constraints: BoxConstraints(minHeight: 30)),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: navItems(),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    // onTap: widget.isNetworkHealthy == null ? () {} : null,
                    onTap: () {
                      showAvailableNetworks(
                          context, networkId == null ? Strings.noAvailableNetworks : networkId, rpcUrl);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          networkId == null ? Strings.noAvailableNetworks : networkId,
                          style: TextStyle(
                              fontFamily: 'Mulish',
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 15,
                              letterSpacing: 1),
                        ),
                        SizedBox(width: 10),
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
                  SizedBox(height: 30),
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        Strings.copyRight,
                        style: TextStyle(
                          color: KiraColors.kGrayColor,
                          fontSize: 14,
                        ),
                      ))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

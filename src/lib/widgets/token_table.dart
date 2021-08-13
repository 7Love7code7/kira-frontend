import 'dart:math';
import 'dart:ui';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

class TokenTable extends StatefulWidget {
  final List<Token> tokens;
  final String expandedName;
  final Function onTapRow;
  final Function onRefresh;
  final String address;
  final bool isLoggedIn;
  final int page;
  final Function setPage;

  TokenTable({
    Key key,
    this.tokens,
    this.expandedName,
    this.onTapRow,
    this.onRefresh,
    this.address,
    this.isLoggedIn,
    this.page,
    this.setPage,
  }) : super();

  @override
  TokenTableState createState() => TokenTableState();
}

class TokenTableState extends State<TokenTable> {
  List<ExpandableController> controllers = List.filled(PAGE_COUNT, null);
  final _tokenService = getIt<TokenService>();
  bool isLoading = false;
  int startAt;
  int endAt;
  List<Token> currentTokens = <Token>[];

  @override
  void initState() {
    super.initState();

    setPage();
  }

  setPage({int newPage = 0}) {
    if (!mounted) return;
    if (newPage > 0) widget.setPage(newPage);
    var page = newPage == 0 ? widget.page : newPage;
    this.setState(() {
      startAt = page * PAGE_COUNT - PAGE_COUNT;
      endAt = startAt + PAGE_COUNT;

      currentTokens = [];
      if (widget.tokens.length > startAt)
        currentTokens = widget.tokens.sublist(startAt, min(endAt, widget.tokens.length));
    });
    if (newPage > 0) refreshExpandStatus();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
            child: ExpandableTheme(
                data: ExpandableThemeData(
                  iconColor: KiraColors.white,
                  useInkWell: true,
                ),
                child: Column(children: <Widget>[
                  addNavigateControls(),
                  addTableHeader(),
                  ...currentTokens
                      .map((token) => ExpandableNotifier(
                            child: ScrollOnExpand(
                              scrollOnExpand: true,
                              scrollOnCollapse: false,
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                color: KiraColors.kBackgroundColor.withOpacity(0.2),
                                child: ExpandablePanel(
                                  theme: ExpandableThemeData(
                                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                                    tapHeaderToExpand: false,
                                    hasIcon: false,
                                  ),
                                  header: addRowHeader(token),
                                  collapsed: Container(),
                                  expanded: addRowBody(token),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ]))));
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

  Widget addNavigateControls() {
    var totalPages = (widget.tokens.length / PAGE_COUNT).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        IconButton(
          onPressed: widget.page > 1 ? () => setPage(newPage: widget.page - 1) : null,
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: widget.page > 1 ? KiraColors.white : KiraColors.kGrayColor.withOpacity(0.2),
          ),
        ),
        Text("${min(widget.page, totalPages)} / $totalPages",
            style: TextStyle(fontSize: 16, color: KiraColors.white, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: widget.page < totalPages ? () => setPage(newPage: widget.page + 1) : null,
          icon: Icon(Icons.arrow_forward_ios,
              size: 20, color: widget.page < totalPages ? KiraColors.white : KiraColors.kGrayColor.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget addTableHeader() {
    List<String> titles = ['Token Name', 'Balance'];

    return Container(
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 15, right: 40, bottom: 15),
      child: Row(
        children: titles
            .asMap()
            .map(
              (index, title) => MapEntry(
                  index,
                  Expanded(
                      flex: 1,
                      child: InkWell(
                          onTap: () => this.setState(() {}),
                          child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                            Text(title,
                                style:
                                    TextStyle(color: KiraColors.kGrayColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          ])))),
            )
            .values
            .toList(),
      ),
    );
  }

  refreshExpandStatus({String newExpandName = ''}) {
    widget.onTapRow(newExpandName);
    this.setState(() {
      currentTokens.asMap().forEach((index, token) {
        controllers[index].expanded = token.assetName == newExpandName;
      });
    });
  }

  Widget addRowHeader(Token token) {
    return Builder(builder: (context) {
      var controller = ExpandableController.of(context);
      controllers[currentTokens.indexOf(token)] = controller;

      return InkWell(
        onTap: () {
          var newExpandName = token.assetName != widget.expandedName ? token.assetName : '';
          refreshExpandStatus(newExpandName: newExpandName);
        },
        child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(width: 50),
                Expanded(
                    flex: ResponsiveWidget.isSmallScreen(context) ? 3 : 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.network('https://cors-anywhere.kira.network/' + token.graphicalSymbol,
                            placeholderBuilder: (BuildContext context) => const CircularProgressIndicator(),
                            width: 32,
                            height: 32),
                        SizedBox(width: 15),
                        Flexible(child: Text(token.assetName,
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16),
                        ))
                      ],
                    )),
                Expanded(
                    flex: 2,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Flexible(child: Text(
                          token.getTokenBalanceInTicker.toString() + " " + token.ticker,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16),
                        )))),
                ExpandableIcon(
                  theme: const ExpandableThemeData(
                    expandIcon: Icons.arrow_right,
                    collapseIcon: Icons.arrow_drop_down,
                    iconColor: Colors.white,
                    iconSize: 28,
                    iconRotationAngle: pi / 2,
                    iconPadding: EdgeInsets.only(right: 5),
                    hasIcon: false,
                  ),
                ),
              ],
            )),
      );
    });
  }

  Widget addRowBody(Token token) {
    final fieldWidth = ResponsiveWidget.isSmallScreen(context) ? 100.0 : 150.0;

    return Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 50),
        child: Column(children: [
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text("Token Name : ",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold))),
              SizedBox(width: 20),
              Flexible(
                  child: Text(token.assetName,
                      overflow: TextOverflow.fade,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14))),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text("Ticker : ",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold))),
              SizedBox(width: 20),
              Flexible(
                  child: Text(token.ticker,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14))),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text("Balance : ",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold))),
              SizedBox(width: 20),
              Text(token.balance.toString(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text("Denomination : ",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold))),
              SizedBox(width: 20),
              Text(token.denomination,
                  overflow: TextOverflow.fade,
                  style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text("Decimals : ",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold))),
              SizedBox(width: 20),
              Text(token.decimals.toString(),
                  overflow: TextOverflow.fade,
                  style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
          SizedBox(height: 20),
          widget.isLoggedIn
              ? Row(
                  children: [
                    CustomButton(
                      key: Key(Strings.faucet),
                      text: Strings.faucet,
                      width: 90,
                      height: 40,
                      style: 1,
                      fontSize: 15,
                      onPressed: () async {
                        if (widget.address.length > 0) {
                          setState(() {
                            isLoading = true;
                          });
                          String result = await _tokenService.faucet(widget.address, token.denomination);
                          setState(() {
                            isLoading = false;
                          });
                          showToast(result);
                          widget.onRefresh();
                        }
                      },
                    ),
                    if (isLoading) addLoadingIndicator()
                  ],
                )
              : Container(),
          SizedBox(height: 20),
        ]));
  }
}

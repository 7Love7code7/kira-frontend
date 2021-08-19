import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/models/transactions/messages/msg_send.dart';
import 'package:kira_auth/models/transactions/std_coin.dart';
import 'package:kira_auth/models/transactions/std_fee.dart';
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/webcam/qr_code_scanner_web.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class SignatureDialog extends StatefulWidget {
  MsgSend message;
  StdCoin feeV;
  StdFee fee;
  StdTx stdTx;
  Account current;
  dynamic sortedJson;

  var stdMsgData = [];
  double rating = 100;
  SignatureDialog(
      {@required this.current,
      @required this.message,
      @required this.feeV,
      @required this.fee,
      @required this.stdTx,
      @required this.sortedJson});

  @override
  _SignatureDialogState createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  List<String> webcamQRData = [];
  double percentage = 0;
  int stepper = 0;

  void processData(var data, var splitValue) {
    RegExp frames = new RegExp(".{1," + splitValue.toStringAsFixed(0) + "}");
    String str = base64.encode(utf8.encode(data));
    Iterable<Match> matches = frames.allMatches(str);
    var list = matches.map((m) => m.group(0)).toList();
    widget.stdMsgData = [];
    for (var i = 0; i < list.length; i++) {
      var pageCount = i + 1;
      var framesData = {"max": "${list.length}", "page": pageCount, "data": list[i]};
      var jsonFrame = jsonEncode(framesData);

      setState(() {
        widget.stdMsgData.add(jsonFrame);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    var qrData = widget.sortedJson;
    processData(qrData, 100);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          return Future.value(false);
        },
        child: AlertDialog(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          content: Builder(
            builder: (context) {
              return Container(
                  width: 400,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                                color: Color.fromRGBO(0, 26, 69, 1),
                                child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Column(children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              Strings.txConfirmation,
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                          color: Colors.white,
                                          child: SizedBox(
                                              width: 400,
                                              child: Padding(
                                                  padding: const EdgeInsets.all(30.0),
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.stretch,
                                                      children: [
                                                        if (stepper == 0) ...[
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.stretch,
                                                            children: [
                                                              Container(
                                                                  padding: EdgeInsets.all(10.0),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                        Strings.saifuTitle,
                                                                        textAlign: TextAlign.center,
                                                                      ),
                                                                    ],
                                                                  )),
                                                              Container(
                                                                color: Colors.white,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets.all(0.0),
                                                                  child: SaifuFastQR(
                                                                    data: widget.stdMsgData,
                                                                    itemHeight: 300,
                                                                    itemWidth:
                                                                        MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                  ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets.all(0.0),
                                                                child: Column(
                                                                  children: [
                                                                    Container(
                                                                      height: 75,
                                                                      width: 200,
                                                                      padding: EdgeInsets.all(0),
                                                                      decoration: BoxDecoration(
                                                                        image: DecorationImage(
                                                                            image: AssetImage(
                                                                                '/images/app_store.png'),
                                                                            fit: BoxFit.contain),
                                                                      ),
                                                                      child: new TextButton(
                                                                          onPressed: () async {
                                                                            if (await canLaunch(
                                                                                "https://play.google.com/store")) {
                                                                              await launch(
                                                                                  "https://play.google.com/store");
                                                                            } else {
                                                                              throw 'Could not launch null';
                                                                            }
                                                                          },
                                                                          style: ButtonStyle(
                                                                            overlayColor:
                                                                                MaterialStateColor
                                                                                    .resolveWith(
                                                                                        (states) =>
                                                                                            Colors
                                                                                                .transparent),
                                                                          ),
                                                                          child: null),
                                                                    ),
                                                                    SizedBox(
                                                                      height: 5,
                                                                    ),
                                                                    Container(
                                                                      height: 75,
                                                                      width: 200,
                                                                      decoration: BoxDecoration(
                                                                        image: DecorationImage(
                                                                          image: AssetImage(
                                                                              '/images/google_store.png'),
                                                                        ),
                                                                      ),
                                                                      child: new TextButton(
                                                                          onPressed: () async {
                                                                            if (await canLaunch(
                                                                                "https://play.google.com/store")) {
                                                                              await launch(
                                                                                  "https://play.google.com/store");
                                                                            } else {
                                                                              throw 'Could not launch null';
                                                                            }
                                                                          },
                                                                          style: ButtonStyle(
                                                                            overlayColor:
                                                                                MaterialStateColor
                                                                                    .resolveWith(
                                                                                        (states) =>
                                                                                            Colors
                                                                                                .transparent),
                                                                          ),
                                                                          child: null),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        if (stepper == 1) ...[
                                                          SizedBox(
                                                            child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment.stretch,
                                                                children: [
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                        Strings.saifuShowQRTitle,
                                                                        textAlign: TextAlign.center,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets.all(20.0),
                                                                    child: ConstrainedBox(
                                                                      constraints: BoxConstraints(
                                                                          maxWidth: 300,
                                                                          maxHeight: 300),
                                                                      child: QrCodeCameraWeb(
                                                                        qrCodeCallback:
                                                                            (scanData) async {
                                                                          if (mounted &&
                                                                              percentage != 100) {
                                                                            final decoded =
                                                                                jsonDecode(
                                                                                    scanData);
                                                                            int max = int.parse(
                                                                                decoded['max']);

                                                                            var datasize = int
                                                                                .parse(webcamQRData
                                                                                    .toSet()
                                                                                    .length
                                                                                    .toString());
                                                                            setState(() {
                                                                              percentage =
                                                                                  (datasize / max) *
                                                                                      100;
                                                                              webcamQRData
                                                                                  .add(scanData);
                                                                            });
                                                                            if (percentage == 100) {
                                                                              Navigator.pop(
                                                                                  context,
                                                                                  webcamQRData
                                                                                      .toSet()
                                                                                      .toList());
                                                                            }
                                                                          }
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment.center,
                                                                      children: [
                                                                        Text(
                                                                          Strings.saifuScanQRText,
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.all(
                                                                                  8.0),
                                                                          child:
                                                                              CircularProgressIndicator(
                                                                            valueColor:
                                                                                AlwaysStoppedAnimation<
                                                                                        Color>(
                                                                                    Colors.blue),
                                                                            strokeWidth: 1,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          "${percentage.toStringAsFixed(0)}" +
                                                                              "%",
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                        ),
                                                                      ])
                                                                ]),
                                                          )
                                                        ],
                                                      ]))))
                                    ])))),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: IconButton(
                                        onPressed: () {
                                          if (mounted)
                                            setState(() {
                                              if (stepper == 0) {
                                                Navigator.pop(context);
                                              } else {
                                                stepper--;
                                              }
                                            });
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          color: Color.fromRGBO(0, 26, 69, 1),
                                        ),
                                      )))),
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: stepper != 1
                                      ? CircleAvatar(
                                          backgroundColor: Colors.white,
                                          child: IconButton(
                                            onPressed: () {
                                              if (mounted)
                                                setState(() {
                                                  stepper++;
                                                });
                                            },
                                            icon: Icon(
                                              Icons.check,
                                              color: Color.fromRGBO(0, 26, 69, 1),
                                            ),
                                          ))
                                      : Container()))
                        ])
                      ]));
            },
          ),
        ));
  }
}

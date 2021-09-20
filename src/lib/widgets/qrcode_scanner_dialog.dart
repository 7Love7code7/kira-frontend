import 'package:flutter/material.dart';
import 'package:kira_auth/webcam/qr_code_scanner_web.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScannerDialog extends StatefulWidget {
  String title;
  Function qrCodeFunction;

  QrScannerDialog({this.title, this.qrCodeFunction});
  @override
  QrScannerDialogState createState() => QrScannerDialogState();
}

class QrScannerDialogState extends State<QrScannerDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
        content: Container(
            width: 350,
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
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            color: Colors.white,
                            child: SizedBox(
                              width: 350,
                              child:
                                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(30),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: 350),
                                    child: QrCodeCameraWeb(
                                      fit: BoxFit.cover,
                                      qrCodeCallback: (scanData) async {
                                        if (mounted) {
                                          widget.qrCodeFunction();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Don't have Saifu wallet app?",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Container(
                                          height: 75,
                                          width: 200,
                                          padding: EdgeInsets.all(0),
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage('/images/app_store.png'),
                                                fit: BoxFit.contain),
                                          ),
                                          child: new TextButton(
                                              onPressed: () async {
                                                if (await canLaunch(
                                                    "https://play.google.com/store")) {
                                                  await launch("https://play.google.com/store");
                                                } else {
                                                  throw 'Could not launch null';
                                                }
                                              },
                                              style: ButtonStyle(
                                                overlayColor: MaterialStateColor.resolveWith(
                                                    (states) => Colors.transparent),
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
                                              image: AssetImage('/images/google_store.png'),
                                            ),
                                          ),
                                          child: new TextButton(
                                              onPressed: () async {
                                                if (await canLaunch(
                                                    "https://play.google.com/store")) {
                                                  await launch("https://play.google.com/store");
                                                } else {
                                                  throw 'Could not launch null';
                                                }
                                              },
                                              style: ButtonStyle(
                                                overlayColor: MaterialStateColor.resolveWith(
                                                    (states) => Colors.transparent),
                                              ),
                                              child: null),
                                        ),
                                      ],
                                    ),
                                  ),
                                ])
                              ]),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )));
  }
}

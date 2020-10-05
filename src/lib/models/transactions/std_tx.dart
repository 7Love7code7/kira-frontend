import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:kira_auth/models/transactions/export.dart';

class StdTx {
  final StdMsg stdMsg;
  final AuthInfo authInfo;
  final List<StdSignature> signatures;

  StdTx({
    @required this.stdMsg,
    @required this.authInfo,
    @required this.signatures,
  })  : assert(stdMsg != null),
        assert(authInfo != null),
        assert(signatures == null || signatures.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'body': this.stdMsg.toJson(),
        'auth_info': this.authInfo.toJson(),
        'signatures':
            this.signatures?.map((signature) => signature.toJson())?.toList(),
      };

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
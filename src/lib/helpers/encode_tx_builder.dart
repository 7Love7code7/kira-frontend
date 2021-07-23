import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/utils/export.dart';

class EncodeTransactionBuilder {
  static Future<StdEncodeMessage> buildEncodeTx(
    Account account,
    List<MsgSend> messages, {
    String memo = '',
    StdFee stdFee,
  }) async {
    // Validate the messages
    messages.forEach((msg) {
      final error = msg.validate();
      if (error != null) {
        throw error;
      }
    });

    final CosmosAccount cosmosAccount = await QueryService.getAccountData(account);

    NodeInfo nodeInfo = await getNodeStatusData("NODE_INFO");

    final stdEncodeTx = StdEncodeTx(msg: messages, fee: stdFee, signatures: null, memo: memo);

    return StdEncodeMessage(
        chainId: nodeInfo.network,
        accountNumber: cosmosAccount.accountNumber,
        sequence: cosmosAccount.sequence,
        tx: stdEncodeTx);
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kira_auth/models/token_model.dart';
import 'package:kira_auth/utils/token_icons.dart';

class TokenService {
  List<TokenModel> tokens = List();

  Future<void> getTokens({address}) async {
    List<TokenModel> tokens;

    var data = await http
        .get("http://0.0.0.0:11000/api/cosmos/bank/balances/$address");

    var jsonData = json.decode(data.body);

    tokens.add(TokenModel.fromJson(jsonData['response']));
  }

  void getDummyTokens() {
    var tokenData = [
      {
        "graphical_symbol": TokenIcons.kex,
        "asset_name": 'Kira',
        "ticker": 'KEX',
        "balance": 1000,
        "denomination": 'ukex',
        "decimals": 6,
        "pagination": {"nextKey": "0", "total": 0}
      },
      {
        "graphical_symbol": TokenIcons.btc,
        "asset_name": 'Bitcoin',
        "ticker": 'BTC',
        "balance": 532,
        "denomination": 'ubtc',
        "decimals": 6,
        "pagination": {"nextKey": "0", "total": 0}
      },
      {
        "graphical_symbol": TokenIcons.atom,
        "asset_name": 'Cosmos',
        "ticker": 'ATOM',
        "balance": 236,
        "denomination": 'uatom',
        "decimals": 6,
        "pagination": {"nextKey": "0", "total": 0}
      },
      {
        "graphical_symbol": TokenIcons.sent,
        "asset_name": 'Sentinel',
        "ticker": 'SENT',
        "balance": 64,
        "denomination": 'usent',
        "decimals": 6,
        "pagination": {"nextKey": "0", "total": 0}
      },
      {
        "graphical_symbol": TokenIcons.eth,
        "asset_name": 'Ethereum',
        "ticker": 'ETH',
        "balance": 747,
        "denomination": 'ueth',
        "decimals": 6,
        "pagination": {"nextKey": "0", "total": 0}
      },
      {
        "graphical_symbol": TokenIcons.eusd,
        "asset_name": 'e-money USD',
        "ticker": 'eUSD',
        "balance": 100,
        "denomination": 'eusd',
        "decimals": 6,
        "pagination": {"nextKey": "0", "total": 0}
      },
      {
        "graphical_symbol": TokenIcons.eeur,
        "asset_name": 'e-money EUR',
        "ticker": 'eEUR',
        "balance": 23,
        "denomination": 'ueur',
        "decimals": 6,
        "pagination": {"nextKey": "0", "total": 0}
      }
    ];

    for (int i = 0; i < tokenData.length; i++) {
      TokenModel token = TokenModel.fromJson(tokenData[i]);
      tokens.add(token);
    }
  }
}
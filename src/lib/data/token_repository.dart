import 'package:shared_preferences/shared_preferences.dart';
import 'package:kira_auth/models/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/service_manager.dart';

abstract class TokenRepository {
  Future<Token> getFeeTokenFromCache();
  Future<List<Token>> getTokens(address);
}

class ITokenRepository implements TokenRepository {
  @override
  Future<Token> getFeeTokenFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String feeTokenString = prefs.getString('FEE_TOKEN');

    return Token.fromString(feeTokenString);
  }

  @override
  Future<List<Token>> getTokens(address) async {
    final _tokenService = getIt<TokenService>();
    await _tokenService.getTokens(address);
    return _tokenService.tokens;
  }
}

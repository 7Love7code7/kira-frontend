import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart';
import 'package:kira_auth/utils/bech32_encoder.dart';
import 'package:kira_auth/utils/pc_utils.dart' as pcUtils;
import 'package:kira_auth/utils/tx_signer.dart';
import 'package:kira_auth/models/network_info_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'account_model.g.dart';

/// Represents a account which contains the hex private key, the hex public key
/// and the hex hexAddress.
/// In order to create one properly, the [AccountModel.derive] method should always
/// be used.
/// The associated [networkInfo] will be used when computing the [bech32Address]
/// associated with the account.

@JsonSerializable(
    explicitToJson: true, nullable: false, fieldRename: FieldRename.snake)
class AccountModel {
  static const BASE_DERIVATION_PATH = "m/44'/118'/0'/0";

  String name;
  String version;
  String algorithm;
  String secretKey;
  String encryptedMnemonic;
  String checksum;

  final String hexAddress;
  final String privateKey;
  final String publicKey;

  final NetworkInfo networkInfo;

  AccountModel({
    this.name = "",
    this.version = 'v0.0.1',
    this.algorithm = 'AES-256',
    this.secretKey = "",
    this.encryptedMnemonic = "",
    this.checksum = "",
    @required this.networkInfo,
    @required this.hexAddress,
    @required this.privateKey,
    @required this.publicKey,
  })  : assert(networkInfo != null),
        assert(privateKey != null),
        assert(publicKey != null),
        assert(hexAddress != null);

  factory AccountModel.derive(
    List<String> mnemonic,
    NetworkInfo networkInfo, {
    String lastDerivationPathSegment = "0",
  }) {
    // Get the mnemonic as a string
    final mnemonicString = mnemonic.join(' ');
    if (!bip39.validateMnemonic(mnemonicString)) {
      throw Exception("Invalid mnemonic " + mnemonicString);
    }

    final _lastDerivationPathSegmentCheck =
        int.tryParse(lastDerivationPathSegment) ?? -1;
    if (_lastDerivationPathSegmentCheck < 0)
      throw Exception("Invalid index format $lastDerivationPathSegment");

    // Convert the mnemonic to a BIP32 instance
    final seed = bip39.mnemonicToSeed(mnemonicString);
    final root = bip32.BIP32.fromSeed(seed);

    // Get the node from the derivation path
    final derivedNode =
        root.derivePath("$BASE_DERIVATION_PATH/$lastDerivationPathSegment");

    // Get the curve data
    final secp256k1 = ECCurve_secp256k1();
    final point = secp256k1.G;

    // Compute the curve point associated to the private key
    final bigInt = BigInt.parse(HEX.encode(derivedNode.privateKey), radix: 16);
    final curvePoint = point * bigInt;

    // Get the public key
    final publicKeyBytes = curvePoint.getEncoded();

    // Get the hexAddress
    final sha256Digest = SHA256Digest().process(publicKeyBytes);
    final hexAddress = RIPEMD160Digest().process(sha256Digest);

    // Return the key bytes
    return AccountModel(
      name: "",
      version: "v0.0.1",
      algorithm: "AES-256",
      secretKey: "",
      encryptedMnemonic: "",
      checksum: "",
      hexAddress: HEX.encode(hexAddress),
      publicKey: HEX.encode(publicKeyBytes),
      privateKey: HEX.encode(derivedNode.privateKey),
      networkInfo: networkInfo,
    );
  }

  factory AccountModel.fromString(String data) {
    Map accMap = json.decode(data);
    return AccountModel.fromJson(accMap);
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Creates a new [AccountModel] instance based on the existent [account] for
  /// the given [networkInfo].
  factory AccountModel.convert(AccountModel account, NetworkInfo networkInfo) {
    return AccountModel(
      name: account.name,
      version: account.version,
      algorithm: account.algorithm,
      secretKey: account.secretKey,
      encryptedMnemonic: account.encryptedMnemonic,
      checksum: account.checksum,
      hexAddress: account.hexAddress,
      privateKey: account.privateKey,
      publicKey: account.publicKey,
      networkInfo: networkInfo,
    );
  }

  /// Returns the associated [hexAddress] as a Bech32 string.
  String get bech32Address =>
      Bech32Encoder.encode(networkInfo.bech32Hrp, HEX.decode(hexAddress));

  /// Returns the associated [publicKey] as a Bech32 string
  String get bech32PublicKey {
    final type = [235, 90, 233, 135, 33]; // "addwnpep"
    final prefix = networkInfo.bech32Hrp + "pub";
    final fullPublicKey = Uint8List.fromList(type + HEX.decode(publicKey));
    return Bech32Encoder.encode(prefix, fullPublicKey);
  }

  /// Returns the associated [privateKey] as an [ECPrivateKey] instance.
  ECPrivateKey get _ecPrivateKey {
    final privateKeyInt = BigInt.parse(privateKey, radix: 16);
    return ECPrivateKey(privateKeyInt, ECCurve_secp256k1());
  }

  /// Returns the associated [publicKey] as an [ECPublicKey] instance.
  ECPublicKey get ecPublicKey {
    final secp256k1 = ECCurve_secp256k1();
    final point = secp256k1.G;
    final curvePoint = point * _ecPrivateKey.d;
    return ECPublicKey(curvePoint, ECCurve_secp256k1());
  }

  /// Signs the given [data] using the associated [privateKey] and encodes
  /// the signature bytes to be included inside a transaction.
  Uint8List signTxData(Uint8List data) {
    final hash = SHA256Digest().process(data);
    return TransactionSigner.deriveFrom(hash, _ecPrivateKey, ecPublicKey);
  }

  /// Generates a SecureRandom
  static SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seed = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));
    return secureRandom;
  }

  static ECSignature _toCanonicalised(ECSignature signature) {
    final ECDomainParameters _params = ECCurve_secp256k1();
    final BigInt _halfCurveOrder = _params.n >> 1;
    if (signature.s.compareTo(_halfCurveOrder) > 0) {
      final canonicalisedS = _params.n - signature.s;
      signature = ECSignature(signature.r, canonicalisedS);
    }
    return signature;
  }

  /// Signs the given [data] using the private key associated with this account,
  /// returning the signature bytes ASN.1 DER encoded.
  Uint8List sign(Uint8List data) {
    final ecdsaSigner = Signer("SHA-256/ECDSA")
      ..init(
          true,
          ParametersWithRandom(
            PrivateKeyParameter(_ecPrivateKey),
            _getSecureRandom(),
          ));
    ECSignature ecSignature =
        _toCanonicalised(ecdsaSigner.generateSignature(data));
    final sigBytes = Uint8List.fromList(
      pcUtils.encodeBigInt(ecSignature.r) + pcUtils.encodeBigInt(ecSignature.s),
    );
    return sigBytes;
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  Map<String, dynamic> toJson() => _$AccountModelToJson(this);
}

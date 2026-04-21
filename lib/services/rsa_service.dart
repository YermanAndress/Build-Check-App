import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

class RsaService {
  RSAPublicKey? _publicKey;

  void loadPublicKey(String base64Key) {
    final keyBytes = base64Decode(base64Key);
    _publicKey = _parsePublicKey(keyBytes);
  }

  String encrypt(String plainText) {
    assert(_publicKey != null, 'Llave pública no cargada');

    // ✅ PKCS1Padding — igual que el backend: RSA/ECB/PKCS1Padding
    final cipher = PKCS1Encoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(_publicKey!));

    final input = Uint8List.fromList(utf8.encode(plainText));
    final encrypted = cipher.process(input);
    return base64Encode(encrypted);
  }

  RSAPublicKey _parsePublicKey(Uint8List bytes) {
    final spkiSequence = ASN1Parser(bytes).nextObject() as ASN1Sequence;
    final pubKeyBitString = spkiSequence.elements![1] as ASN1BitString;
    final pubKeyBytes = pubKeyBitString.encodedBytes!;

    // Buscar el inicio de la secuencia interna (0x30)
    int seqStart = 0;
    for (int i = 0; i < pubKeyBytes.length; i++) {
      if (pubKeyBytes[i] == 0x30) {
        seqStart = i;
        break;
      }
    }

    final innerSeq = ASN1Parser(
      Uint8List.fromList(pubKeyBytes.sublist(seqStart)),
    ).nextObject() as ASN1Sequence;

    final modulus  = (innerSeq.elements![0] as ASN1Integer).valueAsBigInteger!;
    final exponent = (innerSeq.elements![1] as ASN1Integer).valueAsBigInteger!;

    return RSAPublicKey(modulus, exponent);
  }
}
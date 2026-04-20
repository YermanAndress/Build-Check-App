import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

class RsaService {
  RSAPublicKey? _publicKey;

  /// Carga la llave pública desde el Base64 que devuelve el backend
  void loadPublicKey(String base64Key) {
    final keyBytes = base64Decode(base64Key);
    _publicKey = _parsePublicKey(keyBytes);
  }

  /// Encripta un texto plano con la llave pública
  String encrypt(String plainText) {
    assert(_publicKey != null, 'Llave pública no cargada');
    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(_publicKey!));
    // Nota: si el backend usa PKCS1Padding, reemplaza OAEPEncoding por PKCS1Encoding
    final input = Uint8List.fromList(utf8.encode(plainText));
    final encrypted = cipher.process(input);
    return base64Encode(encrypted);
  }

  RSAPublicKey _parsePublicKey(Uint8List bytes) {
  // Usar el parser nativo de pointycastle para SubjectPublicKeyInfo
  final spkiSequence = ASN1Parser(bytes).nextObject() as ASN1Sequence;
  
  // Extraer el bitstring con los bytes de la llave
  final pubKeyBitString = spkiSequence.elements![1] as ASN1BitString;
  
  // Los bytes reales empiezan después del tag (1) + length (?) + unused bits (1)
  // La forma más segura es buscar la secuencia RSA dentro del bitstring
  final pubKeyBytes = pubKeyBitString.encodedBytes!;
  
  // Encontrar donde empieza la secuencia (byte 0x30) dentro del bitstring
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
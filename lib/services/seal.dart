import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Pure-Dart implementation of libsodium `crypto_box_seal`, the exact
/// construction GitHub requires for Actions secrets encryption:
///   sealed = ephemeral_x25519_pubkey || crypto_box(msg, nonce, pk, eph_sk)
///   nonce  = blake2b(eph_pub || recipient_pub, 24 bytes)
///   box    = XSalsa20-Poly1305 keyed by HSalsa20(x25519_shared, 0^16)
class GitHubSeal {
  /// Encrypts [message] for the repository public key (base64-decoded [recipientPkBytes]).
  static Future<Uint8List> seal(Uint8List message, Uint8List recipientPkBytes) async {
    if (recipientPkBytes.length != 32) {
      throw ArgumentError('recipient public key must be 32 bytes');
    }
    final x25519 = X25519();
    final eph = await x25519.newKeyPair();
    final ephPub = Uint8List.fromList((await eph.extractPublicKey()).bytes);
    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: eph,
      remotePublicKey: SimplePublicKey(recipientPkBytes, type: KeyPairType.x25519),
    );
    final shared = Uint8List.fromList(await sharedSecret.extractBytes());

    final nonceDigest = await Blake2b(hashLengthInBytes: 24)
        .hash(Uint8List.fromList([...ephPub, ...recipientPkBytes]));
    final nonce = Uint8List.fromList(nonceDigest.bytes);

    final box = _cryptoBox(message, nonce, shared);
    return Uint8List.fromList([...ephPub, ...box]);
  }

  /// Counterpart of [seal] (crypto_box_seal_open) — used for self-tests.
  static Future<Uint8List> open(Uint8List sealed, Uint8List recipientSeed) async {
    if (sealed.length < 32 + 16) throw ArgumentError('sealed message too short');
    final ephPub = sealed.sublist(0, 32);
    final box = sealed.sublist(32);
    final recipient = await X25519().newKeyPairFromSeed(recipientSeed);
    final recipientPub = Uint8List.fromList((await recipient.extractPublicKey()).bytes);
    final shared = await X25519().sharedSecretKey(
      keyPair: recipient,
      remotePublicKey: SimplePublicKey(ephPub, type: KeyPairType.x25519),
    );
    final sharedBytes = Uint8List.fromList(await shared.extractBytes());
    final nonceDigest = await Blake2b(hashLengthInBytes: 24).hash(Uint8List.fromList([...ephPub, ...recipientPub]));
    final nonce = Uint8List.fromList(nonceDigest.bytes);
    return _cryptoBoxOpen(box, nonce, sharedBytes);
  }

  static Uint8List _cryptoBoxOpen(Uint8List box, Uint8List nonce24, Uint8List shared32) {
    final key = _hSalsa20(shared32, Uint8List(16));
    final subKey = _hSalsa20(key, nonce24.sublist(0, 16));
    final nonce8 = nonce24.sublist(16, 24);
    final block0 = _salsa20Block(subKey, nonce8, 0);
    final polyKey = block0.sublist(0, 32);

    final tag = box.sublist(0, 16);
    final ct = box.sublist(16);
    final check = _poly1305(polyKey, ct);
    var difference = 0;
    for (var i = 0; i < 16; i++) {
      difference |= check[i] ^ tag[i];
    }
    if (difference != 0) throw StateError('poly1305 tag mismatch');
    return _xsalsa20Xor(ct, subKey, nonce8);
  }

  // ── crypto_box (xsalsa20-poly1305) ────────────────────────────────────────

  static Uint8List _cryptoBox(Uint8List msg, Uint8List nonce24, Uint8List shared32) {
    final key = _hSalsa20(shared32, Uint8List(16));
    final subKey = _hSalsa20(key, nonce24.sublist(0, 16));
    final nonce8 = nonce24.sublist(16, 24);

    // First salsa20 block → one-time poly1305 key.
    final block0 = _salsa20Block(subKey, nonce8, 0);
    final polyKey = block0.sublist(0, 32);

    // Secretbox uses bytes 32..63 of block zero before moving to block one.
    final out = _xsalsa20Xor(msg, subKey, nonce8);
    final tag = _poly1305(polyKey, out);
    return Uint8List.fromList([...tag, ...out]);
  }

  static Uint8List _xsalsa20Xor(Uint8List input, Uint8List key, Uint8List nonce8) {
    final out = Uint8List(input.length);
    var offset = 0;
    var counter = 0;
    var start = 32; // The first 32 bytes are reserved for the Poly1305 key.
    while (offset < input.length) {
      final block = _salsa20Block(key, nonce8, counter++);
      for (var i = start; i < 64 && offset < input.length; i++, offset++) {
        out[offset] = input[offset] ^ block[i];
      }
      start = 0;
    }
    return out;
  }

  // ── Salsa20 core ──────────────────────────────────────────────────────────

  static const List<int> _sigma = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574];

  static int _rotl(int v, int c) => ((v << c) | (v >>> (32 - c))) & 0xFFFFFFFF;

  static void _quarter(Uint32List x, int a, int b, int c, int d) {
    x[b] ^= _rotl((x[a] + x[d]) & 0xFFFFFFFF, 7);
    x[c] ^= _rotl((x[b] + x[a]) & 0xFFFFFFFF, 10);
    x[d] ^= _rotl((x[c] + x[b]) & 0xFFFFFFFF, 13);
    x[a] ^= _rotl((x[d] + x[c]) & 0xFFFFFFFF, 18);
  }

  static Uint32List _rounds(Uint32List input) {
    final x = Uint32List.fromList(input);
    for (var i = 0; i < 10; i++) {
      // columnround
      _quarter(x, 0, 4, 8, 12);
      _quarter(x, 5, 9, 13, 1);
      _quarter(x, 10, 14, 2, 6);
      _quarter(x, 15, 3, 7, 11);
      // rowround
      _quarter(x, 0, 1, 2, 3);
      _quarter(x, 5, 6, 7, 4);
      _quarter(x, 10, 11, 8, 9);
      _quarter(x, 15, 12, 13, 14);
    }
    return x;
  }

  /// HSalsa20: 32-byte key + 16-byte input → 32-byte subkey (no final add).
  static Uint8List _hSalsa20(Uint8List key, Uint8List n16) {
    final x = Uint32List(16);
    x[0] = _sigma[0];
    x[5] = _sigma[1];
    x[10] = _sigma[2];
    x[15] = _sigma[3];
    for (var i = 0; i < 4; i++) {
      x[1 + i] = _le32(key, i * 4);
      x[11 + i] = _le32(key, 16 + i * 4);
      x[6 + i] = _le32(n16, i * 4);
    }
    final r = _rounds(x);
    final out = ByteData(32);
    const idx = [0, 1, 2, 3, 12, 13, 14, 15];
    for (var i = 0; i < 8; i++) {
      out.setUint32(i * 4, r[idx[i]], Endian.little);
    }
    return out.buffer.asUint8List();
  }

  /// One 64-byte Salsa20 block for key + 8-byte nonce + 64-bit counter.
  static Uint8List _salsa20Block(Uint8List key, Uint8List nonce8, int counter) {
    final input = Uint32List(16);
    input[0] = _sigma[0];
    input[5] = _sigma[1];
    input[10] = _sigma[2];
    input[15] = _sigma[3];
    for (var i = 0; i < 4; i++) {
      input[1 + i] = _le32(key, i * 4);
      input[11 + i] = _le32(key, 16 + i * 4);
    }
    input[6] = _le32(nonce8, 0);
    input[7] = _le32(nonce8, 4);
    input[8] = counter & 0xFFFFFFFF;
    input[9] = (counter >> 32) & 0xFFFFFFFF;

    final r = _rounds(input);
    final out = ByteData(64);
    for (var i = 0; i < 16; i++) {
      out.setUint32(i * 4, (r[i] + input[i]) & 0xFFFFFFFF, Endian.little);
    }
    return out.buffer.asUint8List();
  }

  static int _le32(Uint8List b, int o) =>
      b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

  // ── Poly1305 ──────────────────────────────────────────────────────────────

  static Uint8List _poly1305(Uint8List key, Uint8List msg) {
    final p = (BigInt.one << 130) - BigInt.from(5);

    final rb = Uint8List.fromList(key.sublist(0, 16));
    rb[3] &= 15;
    rb[7] &= 15;
    rb[11] &= 15;
    rb[15] &= 15;
    rb[4] &= 252;
    rb[8] &= 252;
    rb[12] &= 252;
    final r = _leBigInt(rb);
    final s = _leBigInt(key.sublist(16, 32));

    var acc = BigInt.zero;
    for (var i = 0; i < msg.length; i += 16) {
      final end = (i + 16 > msg.length) ? msg.length : i + 16;
      final block = msg.sublist(i, end);
      var n = _leBigInt(block);
      n += BigInt.one << (8 * block.length);
      acc = ((acc + n) * r) % p;
    }
    acc = (acc + s) % (BigInt.one << 128);

    final out = Uint8List(16);
    var v = acc;
    for (var i = 0; i < 16; i++) {
      out[i] = (v & BigInt.from(255)).toInt();
      v = v >> 8;
    }
    return out;
  }

  static BigInt _leBigInt(Uint8List b) {
    var v = BigInt.zero;
    for (var i = b.length - 1; i >= 0; i--) {
      v = (v << 8) | BigInt.from(b[i]);
    }
    return v;
  }
}

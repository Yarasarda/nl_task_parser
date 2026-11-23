import 'dart:typed_data';

/// Eşleştirme için metni katlar: küçük harf, Türkçe harfler ASCII'ye
/// (ç→c, ğ→g, ı/İ→i, ö→o, ş→s, ü→u), tipografik kesme/tire düzleşir.
///
/// Uzunluk birebir korunur; böylece katlanmış metindeki konumlar özgün
/// girdideki konumlarla aynıdır (vurgulama aralıkları buna dayanır).
String foldForMatch(String s) {
  final out = Uint16List(s.length);
  for (var i = 0; i < s.length; i++) {
    out[i] = _foldUnit(s.codeUnitAt(i));
  }
  return String.fromCharCodes(out);
}

int _foldUnit(int c) {
  if (c >= 0x41 && c <= 0x5A) return c + 32; // A-Z
  if (c == 0x60) return 0x27; // `
  if (c < 0x80) return c;
  switch (c) {
    case 0x130: // İ
    case 0x131: // ı
    case 0xCE: // Î
    case 0xEE: // î
      return 0x69;
    case 0xC7:
    case 0xE7:
      return 0x63; // ç
    case 0x11E:
    case 0x11F:
      return 0x67; // ğ
    case 0xD6:
    case 0xF6:
      return 0x6F; // ö
    case 0x15E:
    case 0x15F:
      return 0x73; // ş
    case 0xDC:
    case 0xFC:
    case 0xDB:
    case 0xFB:
      return 0x75; // ü û
    case 0xC2:
    case 0xE2:
      return 0x61; // â
    case 0x2018:
    case 0x2019:
    case 0x2032:
    case 0xB4:
      return 0x27; // ’ ‘ ′ ´
    case 0x2010:
    case 0x2011:
    case 0x2012:
    case 0x2013:
    case 0x2014:
    case 0x2212:
      return 0x2D; // tireler
    case 0xA0:
    case 0x202F:
    case 0x2009:
      return 0x20; // boşluklar
  }
  if (c >= 0xD800 && c <= 0xDFFF) return c; // vekil çiftler olduğu gibi
  final lower = String.fromCharCode(c).toLowerCase();
  return lower.length == 1 ? lower.codeUnitAt(0) : c;
}

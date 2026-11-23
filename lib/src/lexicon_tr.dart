// Türkçe sözlük. Tüm anahtarlar katlanmış biçimdedir (bkz. fold.dart):
// "çarşamba" → "carsamba", "ağustos" → "agustos".

import 'tokens.dart';

const Map<String, int> trWeekdays = {
  'pazartesi': DateTime.monday,
  'pzt': DateTime.monday,
  'pts': DateTime.monday,
  'sali': DateTime.tuesday,
  'carsamba': DateTime.wednesday,
  'persembe': DateTime.thursday,
  'cuma': DateTime.friday,
  'cumartesi': DateTime.saturday,
  'cmt': DateTime.saturday,
  'cts': DateTime.saturday,
  'pazar': DateTime.sunday,
};

/// Ders programı kısaltmaları. "car", "per" gibi başka dillerde de kelime
/// oldukları için yalnızca hemen ardından bir saat gelince gün sayılır.
const Map<String, int> trWeekdayShort = {
  'sal': DateTime.tuesday,
  'car': DateTime.wednesday,
  'per': DateTime.thursday,
  'cum': DateTime.friday,
  'paz': DateTime.sunday,
};

/// "ocak" yumuşayınca "ocağa" → "ocag", "aralık" → "aralığa" → "aralig".
const Map<String, int> trMonths = {
  'ocak': 1,
  'ocag': 1,
  'subat': 2,
  'mart': 3,
  'nisan': 4,
  'mayis': 5,
  'haziran': 6,
  'temmuz': 7,
  'agustos': 8,
  'eylul': 9,
  'ekim': 10,
  'kasim': 11,
  'aralik': 12,
  'aralig': 12,
};

const Map<String, int> trNumbers = {
  'bir': 1,
  'iki': 2,
  'uc': 3,
  'dort': 4,
  'bes': 5,
  'alti': 6,
  'yedi': 7,
  'sekiz': 8,
  'dokuz': 9,
  'on': 10,
};

const Map<String, DayPart> trDayParts = {
  'sabah': DayPart.morning,
  'ogleden once': DayPart.morning,
  'ogle': DayPart.noon,
  'oglen': DayPart.noon,
  'ogleyin': DayPart.noon,
  'ogleden sonra': DayPart.afternoon,
  'aksamustu': DayPart.lateAfternoon,
  'aksam': DayPart.evening,
  'gece': DayPart.night,
};

/// Dil tahmini için sık Türkçe sözcükler.
const Set<String> trHints = {
  'bugun',
  'yarin',
  'saat',
  'her',
  'haftaya',
  'kadar',
  'aksam',
  'sabah',
  'gece',
  'ogle',
  'oglen',
  'sonra',
  'gun',
  'gunu',
  'hafta',
  've',
  'ile',
  'arasi',
  'dakika',
  'dk',
  'bucuk',
  'yarim',
  'gelecek',
  'bu',
  'acil',
  'onemli',
  'icin',
  'bir',
  'iki',
  'te',
  'de',
  'da',
  'ta',
  'ara',
  'git',
  'al',
  'yap',
  'oku',
  'toplanti',
  'ders',
  'sinav',
  'odev',
  'ayin',
};

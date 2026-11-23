import 'model.dart';
import 'line_parser.dart';
import 'typo.dart';

/// Kural tabanlı Türkçe/İngilizce ayrıştırıcı. Ağ yok, model yok; her tuşta
/// çalışacak kadar hızlı. Her boş olmayan satır bir görevdir.
///
/// Dil satır başına tahmin edilir; kuralların çoğu iki dilde birden çalışır
/// (karışık girdi olur). Belirsizlik kuralları `date_rules.dart`, güven
/// sezgisi `line_parser.dart` içinde belgelenmiştir.
class RuleExtractor implements TaskExtractor {
  const RuleExtractor();

  @override
  Future<ExtractionResult> extract(String text, {DateTime? now}) async =>
      parse(text, now: now);

  /// [extract]'ın eşzamanlı hali (canlı önizleme için).
  ///
  /// Sonucun güveni satır güvenlerinin en düşüğüdür; görev yoksa 1.0
  /// (yükseltecek bir şey yok).
  ExtractionResult parse(String text, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final tasks = <ExtractedTask>[];
    var start = 0;
    while (start <= text.length) {
      var nl = text.indexOf('\n', start);
      if (nl < 0) nl = text.length;
      var end = nl;
      if (end > start && text.codeUnitAt(end - 1) == 0x0D) end--;
      final task = _parseLine(text.substring(start, end), start, ref);
      if (task != null) tasks.add(task);
      start = nl + 1;
    }
    var confidence = 1.0;
    for (final t in tasks) {
      if (t.confidence < confidence) confidence = t.confidence;
    }
    return ExtractionResult(tasks, confidence: confidence);
  }

  /// Satırı ayrıştırır; tanınmayan bir kelime gün/ay adının yazım yanlışıysa
  /// düzeltilmiş haliyle bir kez daha dener. Düzeltme ancak düzeltilen kelime
  /// gerçekten tanınan bir parçaya dönüşürse kabul edilir; aralıklar özgün
  /// metne geri çevrilir, güven 0.75 ile sınırlanır (önizleme görünür kalır).
  ExtractedTask? _parseLine(String line, int base, DateTime now) {
    final task = parseLine(line, base, now);
    if (task == null) return null;
    final covered = [
      for (final s in task.spans) (s.start - base, s.end - base),
    ];
    final fixes = findTypos(line, covered);
    if (fixes.isEmpty) return task;

    final (fixedLine, back) = applyFixes(line, fixes);
    final fixed = parseLine(fixedLine, 0, now);
    if (fixed == null) return task;

    final spans = <ParsedSpan>[];
    var used = false;
    for (final s in fixed.spans) {
      final os = back(s.start), oe = back(s.end);
      final touches = fixes.any((f) => os < f.end && oe > f.start);
      used |= touches;
      spans.add(ParsedSpan(base + os, base + oe, s.kind, corrected: touches));
    }
    if (!used) return task;
    return fixed.copyWith(
      spans: spans,
      confidence: fixed.confidence < 0.75 ? fixed.confidence : 0.75,
    );
  }
}

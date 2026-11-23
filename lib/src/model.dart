/// Serbest metni (veya PDF'ten çıkan metni) yapılandırılmış göreve çevirir.
abstract class TaskExtractor {
  Future<ExtractionResult> extract(String text, {DateTime? now});
}

/// Girdide tanınan parçanın türü (yazarken canlı vurgulama için).
enum SpanKind { date, time, duration, recurrence, priority, deadline }

/// Özgün girdideki tanınmış parça: `[start, end)` karakter aralığı.
class ParsedSpan {
  const ParsedSpan(this.start, this.end, this.kind, {this.corrected = false});

  final int start;
  final int end;
  final SpanKind kind;

  /// Yazım yanlışı düzeltilerek tanındı ("yrın" → yarın).
  final bool corrected;

  @override
  bool operator ==(Object other) =>
      other is ParsedSpan &&
      other.start == start &&
      other.end == end &&
      other.kind == kind &&
      other.corrected == corrected;

  @override
  int get hashCode => Object.hash(start, end, kind, corrected);

  @override
  String toString() =>
      'ParsedSpan($start, $end, ${kind.name}${corrected ? ', corrected' : ''})';
}

class ExtractedTask {
  const ExtractedTask({
    required this.title,
    this.start,
    this.duration,
    this.recurrence,
    this.priority = 0,
    this.subtasks = const [],
    this.end,
    this.allDay = false,
    this.deadline,
    this.estimate,
    this.spans = const [],
    this.confidence = 1.0,
  });

  final String title;

  /// Başlangıç; [allDay] ise saat 00:00'dır. Tekrarda ilk oluşum.
  final DateTime? start;

  /// Yalnızca saati belli bir başlangıçla birlikte dolu olur.
  final Duration? duration;
  final String? recurrence; // RRULE benzeri, ör. "FREQ=WEEKLY;BYDAY=TU"
  final int priority; // 0 yok, 1 düşük, 2 önemli, 3 acil
  final List<String> subtasks;

  /// Aralıktan ("14-16") ya da başlangıç + süreden gelen bitiş.
  final DateTime? end;

  /// Tarih var, saat yok.
  final bool allDay;

  /// "cumaya kadar" / "by friday": son an. Saatsizse günün 23:59'u.
  final DateTime? deadline;

  /// Sabit saati olmayan iş yükü ("3 saat cumaya kadar").
  final Duration? estimate;

  /// Tanınan parçalar; özgün girdinin tamamına göre karakter konumları.
  final List<ParsedSpan> spans;

  /// Bu satırın güveni (0..1).
  final double confidence;

  ExtractedTask copyWith({
    String? title,
    List<ParsedSpan>? spans,
    double? confidence,
  }) => ExtractedTask(
    title: title ?? this.title,
    start: start,
    duration: duration,
    recurrence: recurrence,
    priority: priority,
    subtasks: subtasks,
    end: end,
    allDay: allDay,
    deadline: deadline,
    estimate: estimate,
    spans: spans ?? this.spans,
    confidence: confidence ?? this.confidence,
  );

  @override
  String toString() =>
      'ExtractedTask(title: "$title", start: $start, '
      'end: $end, allDay: $allDay, duration: $duration, '
      'estimate: $estimate, deadline: $deadline, recurrence: $recurrence, '
      'priority: $priority, subtasks: $subtasks, spans: $spans, '
      'confidence: ${confidence.toStringAsFixed(2)})';
}

class ExtractionResult {
  const ExtractionResult(this.tasks, {required this.confidence});

  final List<ExtractedTask> tasks;

  /// 0..1. Düşükse üst seviye çıkarıcıya (yerel model, bulut) düşülür.
  final double confidence;
}

# nl_task_parser

Rule-based natural-language task parser for **Turkish** and **English**, in pure Dart.

Type a plan the way you would say it, get a structured task back:

```text
"yarın 15'te diş hekimi 45 dk"  →  diş hekimi · Sat 24 Oct 15:00–15:45
"cumaya kadar rapor 3 saat !!"  →  rapor · deadline Fri 23:59 · estimate 3h · priority 2
"every friday 7pm gym"          →  gym · FREQ=WEEKLY;BYDAY=FR · 19:00
```

No network, no model, no dependencies. It is fast enough to run on every keystroke, and it tells you
*which characters* it recognised, so a text field can highlight them live.

## Features

- **Dates:** relative (`yarın`, `öbür gün`, `tomorrow`, `in 3 days`), weekdays (`pazartesi`, `Sal`, `friday`),
  absolute (`15 ekim`, `15.10`, `Oct 15`).
- **Times and ranges:** `15'te`, `saat 9`, `19:00`, `3pm`, `14-16`.
- **Durations and estimates:** `45 dk`, `2 saat`, `1.5h`. Without a fixed time, a duration becomes an estimate.
- **Deadlines:** `cumaya kadar`, `by monday`.
- **Recurrence** as an RRULE string: `her salı` → `FREQ=WEEKLY;BYDAY=TU`.
- **Priority** (`!`, `!!`, `acil`, `urgent`) and **subtasks** (`toplantı: sunum, bütçe`).
- **Typo tolerance:** `yrın`, `perşmbe`, `tomorow`, `fridy` are corrected, and the span is marked `corrected`.
- **Spans + confidence:** every recognised piece comes with its `[start, end)` range in the original input.
  Each task carries a 0–1 confidence, so you can fall back to something heavier (e.g. an on-device LLM)
  only when it is low.
- **Mixed language:** the language is guessed per line, and most rules work in both languages.

## Usage

```dart
import 'package:nl_task_parser/nl_task_parser.dart';

void main() {
  const parser = RuleExtractor();
  final result = parser.parse(
    "yarın 15'te diş hekimi 45 dk",
    now: DateTime(2026, 10, 23, 10), // optional, defaults to DateTime.now()
  );

  final task = result.tasks.single;
  print(task.title);      // diş hekimi
  print(task.start);      // 2026-10-24 15:00:00.000
  print(task.end);        // 2026-10-24 15:45:00.000
  print(task.spans);      // [ParsedSpan(0, 5, date), ParsedSpan(6, 11, time), ParsedSpan(23, 28, duration)]
  print(task.confidence); // 0.95
}
```

Every non-empty line becomes one task, so you can paste several lines at once.
`parse` is synchronous, for live previews. `extract` is the same call behind the async `TaskExtractor`
interface, so you can swap in another implementation.

More inputs and their output: [`example/example.dart`](example/example.dart).

## Output model

| Field | Meaning |
|---|---|
| `title` | What is left after the recognised parts are removed |
| `start`, `end` | Start and end; `end` comes from a range (`14-16`) or start + duration |
| `allDay` | Date without a time |
| `duration` | Only when there is a fixed start time |
| `estimate` | Workload without a fixed time (`3 saat cumaya kadar`) |
| `deadline` | `cumaya kadar` / `by friday`; 23:59 if no time is given |
| `recurrence` | RRULE-like string, e.g. `FREQ=WEEKLY;BYDAY=TU` |
| `priority` | 0 none, 1 low, 2 important, 3 urgent |
| `subtasks` | Items after a colon |
| `spans` | Recognised pieces (`SpanKind`: date, time, duration, recurrence, priority, deadline) |
| `confidence` | 0–1. The result-level confidence is the lowest of its tasks |

`foldForMatch` is exported too. It lowercases a string and folds Turkish letters to ASCII
(`ç→c, ğ→g, ı/İ→i, ö→o, ş→s, ü→u`) without changing its length, so positions in the folded text match the original.

## Türkçe

Düz cümleyle yazılan planı (`yarın 15'te diş hekimi 45 dk`) yapılandırılmış göreve çeviren kural tabanlı
ayrıştırıcı. Tarih, saat, aralık, süre, son tarih, tekrar (RRULE), öncelik ve alt görevleri tanır. Yazım
hatalarını düzeltir. Her parçanın girdideki konumunu ve bir güven skoru döner. Ağ ve model kullanmaz,
bağımlılığı yoktur.

Tamamen yerel çalışan planlayıcı uygulamam Plan'ın ayrıştırıcısından ayrılmıştır. Kaynak koddaki belge
yorumları Türkçedir.

## License

MIT © 2026 Arda Kaan Özsoy

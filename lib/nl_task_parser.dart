/// Rule-based natural-language task parser for Turkish and English.
///
/// Turns a plain sentence such as `yarın 15'te diş hekimi 45 dk` or
/// `every tuesday 7pm gym` into a structured task: title, start, end,
/// duration, deadline, estimate, recurrence (RRULE), priority and subtasks,
/// plus the character spans that were recognised (for live highlighting) and
/// a confidence score. No network, no model; fast enough to run on every
/// keystroke.
///
/// ```dart
/// const parser = RuleExtractor();
/// final result = parser.parse("yarın 15'te diş hekimi 45 dk");
/// final task = result.tasks.single;
/// print(task.title); // diş hekimi
/// ```
library;

export 'src/fold.dart' show foldForMatch;
export 'src/model.dart';
export 'src/rule_extractor.dart' show RuleExtractor;

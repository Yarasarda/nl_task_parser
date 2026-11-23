import 'package:test/test.dart';
import 'package:nl_task_parser/nl_task_parser.dart';

import 'parser_test_utils.dart';

// now = Friday 23 Oct 2026 10:00. This week: 19–25 Oct, next: 26 Oct–1 Nov.

void main() {
  group('EN relative days', () {
    runCases([
      Case(
        'dentist tomorrow 3pm',
        title: 'dentist',
        start: dt(2026, 10, 24, 15),
        allDay: false,
      ),
      Case(
        'call mom today at 6pm',
        title: 'call mom',
        start: dt(2026, 10, 23, 18),
      ),
      Case(
        'day after tomorrow dentist',
        title: 'dentist',
        start: dt(2026, 10, 25),
        allDay: true,
      ),
      Case('pay rent in 3 days', title: 'pay rent', start: dt(2026, 10, 26)),
      Case('checkup in 2 weeks', title: 'checkup', start: dt(2026, 11, 6)),
      Case(
        'visa renewal 2 weeks from now',
        title: 'visa renewal',
        start: dt(2026, 11, 6),
      ),
      Case('team sync next week', title: 'team sync', start: dt(2026, 10, 26)),
      Case('next friday demo', title: 'demo', start: dt(2026, 10, 30)),
      Case('this friday drinks', title: 'drinks', start: dt(2026, 10, 23)),
      Case('next week friday review', title: 'review', start: dt(2026, 10, 30)),
      Case('friday next week review', title: 'review', start: dt(2026, 10, 30)),
      Case('coming tuesday dentist', title: 'dentist', start: dt(2026, 10, 27)),
      Case('tmrw gym', title: 'gym', start: dt(2026, 10, 24)),
      Case('this weekend hike', title: 'hike', start: dt(2026, 10, 24)),
      Case('next month budget', title: 'budget', start: dt(2026, 11, 1)),
    ]);
  });

  group('EN weekdays', () {
    runCases([
      Case('monday standup', title: 'standup', start: dt(2026, 10, 26)),
      Case(
        'lunch with Sam on monday at noon',
        title: 'lunch with Sam',
        start: dt(2026, 10, 26, 12),
      ),
      Case('friday 3pm call', title: 'call', start: dt(2026, 10, 23, 15)),
      Case('Wed 10am dentist', title: 'dentist', start: dt(2026, 10, 28, 10)),
      Case('sat morning hike', title: 'hike', start: dt(2026, 10, 24, 9)),
      Case('on thursday meet Ana', title: 'meet Ana', start: dt(2026, 10, 29)),
      Case(
        'talk to John on friday',
        title: 'talk to John',
        start: dt(2026, 10, 30),
      ),
    ]);
  });

  group('EN absolute dates', () {
    runCases([
      Case('dinner march 12', title: 'dinner', start: dt(2027, 3, 12)),
      Case('flight 12 march', title: 'flight', start: dt(2027, 3, 12)),
      Case('exam mar 12th', title: 'exam', start: dt(2027, 3, 12)),
      Case(
        'conference march 12, 2027',
        title: 'conference',
        start: dt(2027, 3, 12),
      ),
      Case('trip on the 12th of march', title: 'trip', start: dt(2027, 3, 12)),
      Case('party dec 31', title: 'party', start: dt(2026, 12, 31)),
      Case(
        'renew passport 2027-01-15',
        title: 'renew passport',
        start: dt(2027, 1, 15),
      ),
      Case('move on the 30th', title: 'move', start: dt(2026, 10, 30)),
      Case(
        'submit essay until 12 march',
        title: 'submit essay',
        start: null,
        deadline: dt(2027, 3, 12, 23, 59),
      ),
    ]);
  });

  group('EN times', () {
    runCases([
      Case('gym 3:30 pm', title: 'gym', start: dt(2026, 10, 23, 15, 30)),
      // 09:00 has passed → tomorrow.
      Case('meeting at 9', title: 'meeting', start: dt(2026, 10, 24, 9)),
      Case('meeting at 11', title: 'meeting', start: dt(2026, 10, 23, 11)),
      Case('call at 2', title: 'call', start: dt(2026, 10, 23, 14)),
      Case(
        'breakfast 7:45am',
        title: 'breakfast',
        start: dt(2026, 10, 24, 7, 45),
      ),
      Case(
        'check oven 3 p.m.',
        title: 'check oven',
        start: dt(2026, 10, 23, 15),
      ),
      Case(
        'dinner at 8 in the evening',
        title: 'dinner',
        start: dt(2026, 10, 23, 20),
      ),
      Case('dinner tonight', title: 'dinner', start: dt(2026, 10, 23, 19)),
      Case(
        'call dad in 2 hours',
        title: 'call dad',
        start: dt(2026, 10, 23, 12),
      ),
      Case('tea in 30 minutes', title: 'tea', start: dt(2026, 10, 23, 10, 30)),
      Case('run tomorrow morning', title: 'run', start: dt(2026, 10, 24, 9)),
      Case('nap this afternoon', title: 'nap', start: dt(2026, 10, 23, 15)),
      Case(
        'movie at 9pm tomorrow',
        title: 'movie',
        start: dt(2026, 10, 24, 21),
      ),
      Case('lunch at noon', title: 'lunch', start: dt(2026, 10, 23, 12)),
      Case(
        'dinner with mom in the evening',
        title: 'dinner with mom',
        start: dt(2026, 10, 23, 19),
      ),
      Case(
        'Meeting with Design Team at 3pm',
        title: 'Meeting with Design Team',
        start: dt(2026, 10, 23, 15),
      ),
    ]);
  });

  group('EN ranges', () {
    runCases([
      Case(
        'workshop 3-5pm',
        title: 'workshop',
        start: dt(2026, 10, 23, 15),
        end: dt(2026, 10, 23, 17),
        duration: const Duration(hours: 2),
      ),
      Case(
        'office hours from 2 to 4',
        title: 'office hours',
        start: dt(2026, 10, 23, 14),
        end: dt(2026, 10, 23, 16),
      ),
      Case(
        'call between 2 and 4',
        title: 'call',
        start: dt(2026, 10, 23, 14),
        end: dt(2026, 10, 23, 16),
      ),
      Case(
        'meeting 10:00-11:30 tomorrow',
        title: 'meeting',
        start: dt(2026, 10, 24, 10),
        end: dt(2026, 10, 24, 11, 30),
      ),
      Case(
        'shift 9am-5pm monday',
        title: 'shift',
        start: dt(2026, 10, 26, 9),
        end: dt(2026, 10, 26, 17),
      ),
      Case(
        'class 11-1',
        title: 'class',
        start: dt(2026, 10, 23, 11),
        end: dt(2026, 10, 23, 13),
      ),
      Case(
        'study 2pm to 4pm',
        title: 'study',
        start: dt(2026, 10, 23, 14),
        end: dt(2026, 10, 23, 16),
      ),
      Case(
        'workshop 11-2pm',
        start: dt(2026, 10, 23, 11),
        end: dt(2026, 10, 23, 14),
      ),
    ]);
  });

  group('EN durations', () {
    runCases([
      Case(
        'deep work 2 hours tomorrow 9am',
        title: 'deep work',
        start: dt(2026, 10, 24, 9),
        duration: const Duration(hours: 2),
        end: dt(2026, 10, 24, 11),
      ),
      Case(
        'read 90 min',
        title: 'read',
        start: null,
        estimate: const Duration(minutes: 90),
      ),
      Case(
        '1.5 hours piano',
        title: 'piano',
        estimate: const Duration(minutes: 90),
      ),
      Case(
        'piano 1h30m',
        title: 'piano',
        estimate: const Duration(minutes: 90),
      ),
      Case(
        'half an hour stretching',
        title: 'stretching',
        estimate: const Duration(minutes: 30),
      ),
      Case(
        'an hour of email',
        title: 'email',
        estimate: const Duration(hours: 1),
      ),
      Case(
        'write essay 3 hours by friday',
        title: 'write essay',
        start: null,
        estimate: const Duration(hours: 3),
        deadline: dt(2026, 10, 30, 23, 59),
      ),
      Case(
        'presentation tomorrow 2pm for 45 minutes',
        title: 'presentation',
        start: dt(2026, 10, 24, 14),
        duration: const Duration(minutes: 45),
      ),
    ]);
  });

  group('EN recurrence', () {
    runCases([
      Case(
        'water plants every day',
        title: 'water plants',
        rrule: 'FREQ=DAILY',
        allDay: true,
      ),
      Case(
        'yoga every tuesday',
        title: 'yoga',
        rrule: 'FREQ=WEEKLY;BYDAY=TU',
        start: dt(2026, 10, 27),
      ),
      Case(
        'piano every tuesday and thursday 5pm',
        title: 'piano',
        rrule: 'FREQ=WEEKLY;BYDAY=TU,TH',
        start: dt(2026, 10, 27, 17),
      ),
      Case(
        'standup every weekday 9:30',
        title: 'standup',
        rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
        start: dt(2026, 10, 26, 9, 30),
      ),
      Case(
        'brunch weekends',
        title: 'brunch',
        rrule: 'FREQ=WEEKLY;BYDAY=SA,SU',
        start: dt(2026, 10, 24),
      ),
      Case(
        'gym on weekdays at 7am',
        title: 'gym',
        rrule: 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
        start: dt(2026, 10, 26, 7),
      ),
      Case('review weekly', title: 'review', rrule: 'FREQ=WEEKLY'),
      Case('rent monthly', title: 'rent', rrule: 'FREQ=MONTHLY'),
      Case(
        'invoice monthly on the 15th',
        title: 'invoice',
        rrule: 'FREQ=MONTHLY;BYMONTHDAY=15',
        start: dt(2026, 11, 15),
      ),
      Case(
        'pay rent on the 1st of every month',
        title: 'pay rent',
        rrule: 'FREQ=MONTHLY;BYMONTHDAY=1',
        start: dt(2026, 11, 1),
      ),
      Case(
        'every other week team retro',
        title: 'team retro',
        rrule: 'FREQ=WEEKLY;INTERVAL=2',
      ),
      Case('biweekly sync', title: 'sync', rrule: 'FREQ=WEEKLY;INTERVAL=2'),
      Case(
        'every 3 days water cactus',
        title: 'water cactus',
        rrule: 'FREQ=DAILY;INTERVAL=3',
      ),
      Case(
        'every morning 7am run',
        title: 'run',
        rrule: 'FREQ=DAILY',
        start: dt(2026, 10, 24, 7),
      ),
      Case(
        'tuesdays and thursdays swim',
        title: 'swim',
        rrule: 'FREQ=WEEKLY;BYDAY=TU,TH',
      ),
      Case(
        'standup daily 9:30',
        title: 'standup',
        rrule: 'FREQ=DAILY',
        start: dt(2026, 10, 24, 9, 30),
      ),
      Case(
        'birthday every year march 12',
        title: 'birthday',
        rrule: 'FREQ=YEARLY',
        start: dt(2027, 3, 12),
      ),
      Case(
        'every other tuesday book club',
        title: 'book club',
        rrule: 'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU',
        start: dt(2026, 10, 27),
      ),
    ]);
  });

  group('EN priority', () {
    runCases([
      Case('urgent fix login bug', title: 'fix login bug', priority: 3),
      Case('important: renew passport', title: 'renew passport', priority: 2),
      Case('taxes high priority', title: 'taxes', priority: 3),
      Case('!!! server down', title: 'server down', priority: 3),
      Case('buy milk !', title: 'buy milk', priority: 1),
      Case('low priority clean garage', title: 'clean garage', priority: 1),
      Case('asap send invoice', title: 'send invoice', priority: 3),
    ]);
  });

  group('EN deadlines', () {
    runCases([
      Case(
        'submit report by friday 5pm !',
        title: 'submit report',
        start: null,
        deadline: dt(2026, 10, 23, 17),
        priority: 1,
      ),
      Case(
        'finish slides before monday',
        title: 'finish slides',
        deadline: dt(2026, 10, 25, 23, 59),
      ),
      Case(
        'essay due tomorrow',
        title: 'essay',
        deadline: dt(2026, 10, 24, 23, 59),
      ),
      Case(
        'taxes due by march 15',
        title: 'taxes',
        deadline: dt(2027, 3, 15, 23, 59),
      ),
      Case(
        'apply until next friday',
        title: 'apply',
        deadline: dt(2026, 10, 30, 23, 59),
      ),
      Case(
        'reply within 3 days',
        title: 'reply',
        start: null,
        deadline: dt(2026, 10, 26, 23, 59),
      ),
      Case(
        'pay bill by 5pm',
        title: 'pay bill',
        deadline: dt(2026, 10, 23, 17),
      ),
      Case(
        'invoice by end of month',
        title: 'invoice',
        deadline: dt(2026, 10, 31, 23, 59),
      ),
    ]);
  });

  group('EN subtasks', () {
    runCases([
      Case(
        'groceries: milk, eggs and bread',
        title: 'groceries',
        subtasks: ['milk', 'eggs', 'bread'],
      ),
      Case(
        'packing list: passport, charger; adapter',
        title: 'packing list',
        subtasks: ['passport', 'charger', 'adapter'],
      ),
      Case('note: call back', subtasks: const <String>[]),
    ]);
  });

  group('EN spans', () {
    test('date + time', () {
      expect(spansOf('dentist tomorrow 3pm'), [
        ('tomorrow', SpanKind.date),
        ('3pm', SpanKind.time),
      ]);
    });
    test('deadline group + priority', () {
      expect(spansOf('submit report by friday 5pm !'), [
        ('by friday 5pm', SpanKind.deadline),
        ('!', SpanKind.priority),
      ]);
    });
    test('recurrence + time', () {
      expect(spansOf('standup every weekday 9:30'), [
        ('every weekday', SpanKind.recurrence),
        ('9:30', SpanKind.time),
      ]);
    });
    test('duration', () {
      expect(spansOf('read 90 min'), [('90 min', SpanKind.duration)]);
    });
  });

  group('EN confidence', () {
    test('clean > plain > missed date', () {
      final clean = one('dentist tomorrow 3pm').confidence;
      final plain = one('buy milk').confidence;
      final missed = one('meeting 31/02').confidence;
      expect(clean, greaterThan(plain));
      expect(plain, greaterThan(missed));
      expect(missed, lessThan(0.5));
    });
    test('conflicting dates', () {
      expect(one('tomorrow friday call').confidence, lessThan(0.6));
    });
    test('empty title', () {
      expect(one('tomorrow 3pm').confidence, lessThanOrEqualTo(0.4));
    });
  });
}

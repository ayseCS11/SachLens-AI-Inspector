import '../core/signal.dart';

/// Pure Dart rules that cross check the text read from a document.
/// Nothing here touches the network or the disk.
List<Signal> analyzeDocumentText(String text, {DateTime? now}) {
  final clean = text.trim();
  if (clean.length < 20) {
    return const [
      Signal(
        name: 'Text reading',
        suspicion: 0.3,
        weight: 0.5,
        reason:
        'Little or no text could be read from this file, so number and date checks were skipped.',
      ),
    ];
  }

  final lines = clean
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final signals = <Signal>[
    ..._checkTotals(lines),
    ..._checkDates(lines, now ?? DateTime.now()),
    ..._checkScores(lines),
  ];

  if (signals.isEmpty) {
    signals.add(const Signal(
      name: 'Content checks',
      suspicion: 0.2,
      weight: 0.5,
      reason:
      'Text was read, but no totals, dates or scores were found that could be cross checked.',
    ));
  }
  return signals;
}

// ---------------------------------------------------------------------------
// Totals
// ---------------------------------------------------------------------------

final RegExp _numRe =
RegExp(r'(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)(?!\d)');

double? _lastAmount(String line) {
  final matches = _numRe.allMatches(line).toList();
  if (matches.isEmpty) return null;
  return double.tryParse(matches.last.group(1)!.replaceAll(',', ''));
}

String _money(double v) => v.toStringAsFixed(2);

List<Signal> _checkTotals(List<String> lines) {
  double? subtotal;
  double? tax;
  double? total;
  double? discount;
  double? shipping;

  final taxRe = RegExp(r'\b(tax|vat|gst|gct)\b');
  final totalRe = RegExp(
      r'\b(grand total|total due|amount due|total amount|balance due|total)\b');

  for (final raw in lines) {
    if (raw.endsWith('%')) continue; // a rate, not an amount
    final amount = _lastAmount(raw);
    if (amount == null) continue;
    final l = raw.toLowerCase();

    if (l.contains('subtotal') ||
        l.contains('sub total') ||
        l.contains('sub-total')) {
      subtotal = amount;
    } else if (l.contains('total tax') ||
        (taxRe.hasMatch(l) && !totalRe.hasMatch(l))) {
      tax = amount;
    } else if (l.contains('discount')) {
      discount = amount;
    } else if (l.contains('shipping') || l.contains('delivery')) {
      shipping = amount;
    } else if (totalRe.hasMatch(l)) {
      total = amount;
    }
  }

  if (subtotal == null || total == null) return const [];

  final expected =
      subtotal + (tax ?? 0) + (shipping ?? 0) - (discount ?? 0);
  final diff = (expected - total).abs();

  if (diff <= 0.05) {
    return const [
      Signal(
        name: 'Totals',
        suspicion: 0.05,
        weight: 2,
        reason: 'The subtotal, tax and fees add up to the stated total.',
      ),
    ];
  }

  final nothingElse = tax == null && shipping == null && discount == null;
  if (nothingElse) {
    return [
      Signal(
        name: 'Totals',
        suspicion: 0.5,
        weight: 1.5,
        reason:
        'The total (${_money(total)}) differs from the subtotal (${_money(subtotal)}), '
            'but no tax or fees were found. A line may be missing from the reading.',
      ),
    ];
  }

  return [
    Signal(
      name: 'Totals',
      suspicion: 0.75,
      weight: 2.5,
      reason:
      'The parts add up to ${_money(expected)} but the document states ${_money(total)}. '
          'This can be an altered number or a reading error, so check it by hand.',
    ),
  ];
}

// ---------------------------------------------------------------------------
// Dates
// ---------------------------------------------------------------------------

class _ParsedDate {
  final DateTime date;
  final DateTime? alt; // the other reading when day and month are ambiguous
  const _ParsedDate(this.date, this.alt);
}

const Map<String, int> _monthByPrefix = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

const String _monthsPattern =
    r'(jan[a-z]*|feb[a-z]*|mar[a-z]*|apr[a-z]*|may|jun[a-z]*|jul[a-z]*|aug[a-z]*|sep[a-z]*|oct[a-z]*|nov[a-z]*|dec[a-z]*)';

DateTime? _mk(int y, int m, int d) {
  if (y < 1900 || y > 2100 || m < 1 || m > 12 || d < 1 || d > 31) return null;
  final dt = DateTime(y, m, d);
  return (dt.month == m && dt.day == d) ? dt : null;
}

/// Finds dates even when the text reader dropped the spaces ("May20,2026").
List<_ParsedDate> _extractDates(String line) {
  final out = <_ParsedDate>[];
  final lower = line.toLowerCase();

  // 2024-03-15
  for (final m
  in RegExp(r'\b(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\b').allMatches(lower)) {
    final d = _mk(int.parse(m.group(1)!), int.parse(m.group(2)!),
        int.parse(m.group(3)!));
    if (d != null) out.add(_ParsedDate(d, null));
  }

  // 15/03/2024 or 03/15/2024
  for (final m
  in RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})\b').allMatches(lower)) {
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    final y = int.parse(m.group(3)!);
    if (a > 12) {
      final d = _mk(y, b, a);
      if (d != null) out.add(_ParsedDate(d, null));
    } else if (b > 12) {
      final d = _mk(y, a, b);
      if (d != null) out.add(_ParsedDate(d, null));
    } else {
      final primary = _mk(y, b, a); // day first
      final alt = a == b ? null : _mk(y, a, b); // month first
      if (primary != null) out.add(_ParsedDate(primary, alt));
    }
  }

  // 15 March 2024
  for (final m in RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s*' + _monthsPattern + r'\.?,?\s*(\d{4})\b')
      .allMatches(lower)) {
    final month = _monthByPrefix[m.group(2)!.substring(0, 3)];
    if (month == null) continue;
    final d = _mk(int.parse(m.group(3)!), month, int.parse(m.group(1)!));
    if (d != null) out.add(_ParsedDate(d, null));
  }

  // March 15, 2024
  for (final m in RegExp(
      r'\b' + _monthsPattern + r'\.?\s*(\d{1,2})(?:st|nd|rd|th)?,?\s*(\d{4})\b')
      .allMatches(lower)) {
    final month = _monthByPrefix[m.group(1)!.substring(0, 3)];
    if (month == null) continue;
    final d = _mk(int.parse(m.group(3)!), month, int.parse(m.group(2)!));
    if (d != null) out.add(_ParsedDate(d, null));
  }

  return out;
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

List<Signal> _checkDates(List<String> lines, DateTime now) {
  final out = <Signal>[];
  final limit = now.add(const Duration(days: 1));

  final issueRe = RegExp(
      r'(issued|issue\s*date|date\s*of\s*issue|invoice\s*date|dated|\bdate:|awarded|conferred|graduat)');
  final expiryRe = RegExp(
      r'(expir|valid\s*until|valid\s*till|valid\s*through|due\s*date|due\s*on|\bdue\b)');
  final paymentRe = RegExp(
      r'(payment\s*date|date\s*of\s*payment|paid\s*on|date\s*paid|received\s*on)');

  _ParsedDate? issue;
  _ParsedDate? expiry;
  _ParsedDate? payment;
  bool checkedIssue = false;
  bool futureFlagged = false;

  for (final line in lines) {
    final l = line.toLowerCase();
    final dates = _extractDates(line);
    if (dates.isEmpty) continue;

    if (paymentRe.hasMatch(l)) {
      payment ??= dates.first;
      continue;
    }

    final isExpiry = expiryRe.hasMatch(l);
    final isIssue = issueRe.hasMatch(l) && !isExpiry && !l.contains('birth');

    if (isIssue) {
      issue ??= dates.first;
      checkedIssue = true;
      if (!futureFlagged) {
        for (final d in dates) {
          final future = d.date.isAfter(limit) &&
              (d.alt == null || d.alt!.isAfter(limit));
          if (future) {
            futureFlagged = true;
            out.add(Signal(
              name: 'Dates',
              suspicion: 0.75,
              weight: 2,
              reason:
              'The issue date (${_fmtDate(d.date)}) is in the future, which should not happen.',
            ));
            break;
          }
        }
      }
    } else if (isExpiry) {
      expiry ??= dates.first;
    }
  }

  // A document cannot report a payment that happened long after its own date.
  if (issue != null &&
      payment != null &&
      issue.alt == null &&
      payment.alt == null) {
    final gap = payment.date.difference(issue.date).inDays;
    if (gap > 60) {
      out.add(Signal(
        name: 'Timeline',
        suspicion: 0.9,
        weight: 3,
        reason:
        'The document is dated ${_fmtDate(issue.date)} but reports a payment made on ${_fmtDate(payment.date)}, '
            'about $gap days later. A real document cannot describe something that had not happened yet.',
      ));
    }
  }

  if (issue != null &&
      expiry != null &&
      issue.alt == null &&
      expiry.alt == null) {
    if (expiry.date.isBefore(issue.date)) {
      out.add(Signal(
        name: 'Date order',
        suspicion: 0.85,
        weight: 3,
        reason:
        'The expiry or due date (${_fmtDate(expiry.date)}) is before the issue date (${_fmtDate(issue.date)}).',
      ));
    } else {
      out.add(const Signal(
        name: 'Date order',
        suspicion: 0.05,
        weight: 1,
        reason: 'The issue date comes before the expiry or due date.',
      ));
    }
  } else if (checkedIssue && !futureFlagged) {
    out.add(const Signal(
      name: 'Dates',
      suspicion: 0.05,
      weight: 1,
      reason: 'The issue date is not in the future.',
    ));
  }

  return out;
}

// ---------------------------------------------------------------------------
// Scores and grades
// ---------------------------------------------------------------------------

List<Signal> _checkScores(List<String> lines) {
  final out = <Signal>[];
  final context = RegExp(
      r'(gpa|cgpa|grade|marks|score|percentage|attendance|discount|result)');
  final fraction =
  RegExp(r'(\d{1,3}(?:\.\d+)?)\s*/\s*(\d{1,3}(?:\.\d+)?)(?!\s*/)');
  final percent = RegExp(r'(\d{3,}(?:\.\d+)?)\s*%');

  for (final line in lines) {
    final l = line.toLowerCase();
    if (!context.hasMatch(l)) continue;
    if (_extractDates(line).isNotEmpty) continue; // avoid reading dates as scores

    for (final m in fraction.allMatches(l)) {
      final a = double.parse(m.group(1)!);
      final b = double.parse(m.group(2)!);
      if (b > 0 && a > b) {
        out.add(Signal(
          name: 'Scores',
          suspicion: 0.8,
          weight: 2.5,
          reason:
          'A score of ${m.group(1)} out of ${m.group(2)} is impossible. Line: "$line".',
        ));
        return out;
      }
    }

    for (final m in percent.allMatches(l)) {
      final v = double.parse(m.group(1)!);
      if (v > 100) {
        out.add(Signal(
          name: 'Percentages',
          suspicion: 0.8,
          weight: 2.5,
          reason: 'A value of ${m.group(1)} percent is above 100. Line: "$line".',
        ));
        return out;
      }
    }
  }
  return out;
}

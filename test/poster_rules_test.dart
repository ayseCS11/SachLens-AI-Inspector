import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:sachlens/checks/ocr_lines.dart';
import 'package:sachlens/checks/poster_rules.dart';

PosterAnalysis _run(List<String> lines) =>
    analyzePoster(lines.map((t) => OcrLine(t, Rect.zero)).toList());

class _Case {
  final String name;
  final List<String> lines;
  final Set<PosterLevel> levels;
  final List<String> mustFlag;
  final List<String> mustNot;

  const _Case(this.name, this.lines, this.levels,
      {this.mustFlag = const [], this.mustNot = const []});
}

const _high = {PosterLevel.high};
const _calm = {PosterLevel.none};

const _cases = <_Case>[
  // Scam posters
  _Case(
    'fake job, English',
    [
      'URGENT HIRING! Dubai jobs, visa in 7 days.',
      'Earn 5000 daily. Guaranteed visa.',
      'Registration fee Rs 15000, send to Easypaisa 0300 1234567.',
      'WhatsApp only. Apply now, limited seats.',
    ],
    _high,
    mustFlag: [
      'Guaranteed result',
      'Very high daily earnings',
      'Payment by wallet, transfer or crypto',
      'Fast or free visa promise',
    ],
  ),
  _Case(
    'fake scholarship',
    [
      '100% guaranteed admission and full scholarship in Canada.',
      'No IELTS required. Government approved agent.',
      'Contact visaexpert@gmail.com or WhatsApp 0311 1234567.',
    ],
    _high,
    mustFlag: [
      'Guaranteed result',
      'Skips the normal test or interview',
      'Claims official approval',
    ],
  ),
  _Case(
    'investment',
    [
      'Double your money in 30 days.',
      '10% daily profit, risk free. Refer and earn.',
      'Join our trading group: t.me/profitgroup',
    ],
    _high,
    mustFlag: ['Investment promise'],
  ),
  _Case(
    'lottery',
    [
      'Congratulations! You have won Rs 5,000,000 in the Jazz Lucky Draw.',
      'Claim your prize now! Call 0300 1234567',
    ],
    _high,
    mustFlag: ['Prize or lottery offer'],
  ),
  _Case(
    'loan',
    [
      'Instant loan without guarantor in 10 minutes!',
      'No credit check. WhatsApp 0300 1234567',
    ],
    _high,
    mustFlag: ['Loan with no checks'],
  ),
  _Case(
    'Roman Urdu',
    [
      'Dubai visa 100% guarantee. Visa fees pehle jama karwayein.',
      'Roz 5000 kamayein ghar baithe. WhatsApp 0300 1234567',
    ],
    _high,
    mustFlag: ['Guaranteed result', 'Asks for money first'],
  ),
  _Case(
    'Spanish',
    [
      'Gana \$100 diarios trabajando desde casa.',
      'Visa garantizada. Pague primero.',
      'Escribenos por WhatsApp +52 55 1234 5678',
    ],
    _high,
    mustFlag: [
      'Guaranteed result',
      'Asks for money first',
      'Very high daily earnings',
    ],
  ),
  _Case(
    'French',
    [
      'Emploi garanti a l etranger.',
      'Gagnez 200 euros par jour. Payez d abord les frais de dossier.',
    ],
    _high,
    mustFlag: [
      'Guaranteed result',
      'Very high daily earnings',
      'Asks for money first',
    ],
  ),
  _Case(
    'Portuguese',
    [
      'Visto garantido para Portugal. Ganhe R\$ 500 por dia trabalhando em casa.',
      'Pagamento adiantado obrigatorio.',
    ],
    _high,
    mustFlag: [
      'Guaranteed result',
      'Very high daily earnings',
      'Asks for money first',
    ],
  ),

  // Honest posters that must NOT be accused
  _Case(
    'genuine company',
    [
      'ABC Engineering Pvt Ltd, Reg No 12345.',
      'Office 12, 2nd Floor, Gulberg Plaza, Lahore.',
      'We are hiring a site engineer. Apply with your CV at hr@abcengineering.com.',
    ],
    _calm,
    mustNot: ['Asks for money first', 'Guaranteed result'],
  ),
  _Case(
    'genuine university with an application fee',
    [
      'University of Example. Admissions open for Fall 2026.',
      'Application fee \$50 payable on our official website www.example.edu/apply.',
      'Deadline March 1. Contact admissions@example.edu',
    ],
    _calm,
    mustNot: [
      'Asks for money first',
      'Guaranteed result',
      'Payment by wallet, transfer or crypto',
    ],
  ),
  _Case(
    'scam warning poster',
    [
      'Beware of fake job agents! Never pay any visa fee or advance payment.',
      'Report fraud to 1234. Stay safe.',
    ],
    _calm,
    mustNot: ['Asks for money first'],
  ),
  _Case(
    'honest job ad that says no fees',
    [
      'We never ask for any fee. Apply at careers.company.com',
      'Jobs in Dubai for qualified engineers. Send CV only.',
    ],
    _calm,
    mustNot: ['Asks for money first', 'Mentions a fee'],
  ),
  _Case(
    'retail sale',
    [
      'Mega Sale! 50% off all items. Limited time offer until Sunday.',
      'Visit our store at Main Boulevard, Lahore.',
    ],
    _calm,
    mustNot: ['Asks for money first', 'Prize or lottery offer'],
  ),
  _Case(
    'bank poster',
    [
      'HBL: Open a savings account today. Terms apply.',
      'Visit any branch.',
    ],
    _calm,
    mustNot: ['Asks for money first', 'Loan with no checks'],
  ),
  _Case(
    'seminar with a small fee',
    [
      'Free career seminar this Saturday. Registration fee Rs 500 at the door.',
      'Venue: Town Hall, Block B',
    ],
    _calm,
    mustNot: ['Asks for money first', 'Prize or lottery offer'],
  ),
  _Case(
    'fee deadline notice',
    [
      'Pay before the deadline of 30 June to avoid late charges.',
      'Fee vouchers available at the accounts office.',
    ],
    _calm,
    mustNot: ['Asks for money first'],
  ),
];

void main() {
  for (final c in _cases) {
    test(c.name, () {
      final a = _run(c.lines);
      final titles = a.flags.map((f) => f.title).toList();

      expect(
        c.levels.contains(a.level),
        isTrue,
        reason: 'level was ${a.level} (risk ${a.riskPercent}), flags: $titles',
      );
      for (final m in c.mustFlag) {
        expect(titles, contains(m));
      }
      for (final m in c.mustNot) {
        expect(titles, isNot(contains(m)));
      }
    });
  }

  test('text in an unsupported script is not called safe', () {
    final a = _run([
      'ملازمت کے لیے رابطہ کریں 0300 1234567',
      'دبئی ویزا فوری',
    ]);
    expect(a.level, PosterLevel.unreadable);
  });

  test('gibberish is not called safe', () {
    final a = _run([
      'lI|l 0o Xx ~~ ds wlkfh trzzxq',
      'Ill 1l ,, .. ;; ccc vvv bbb xx',
      'qwrtp zzxk mnbvc hjklp',
    ]);
    expect(a.level, PosterLevel.unreadable);
  });
}
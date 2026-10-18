import 'link_check.dart';
import 'ocr_lines.dart';
import 'qr_check.dart';

enum PosterLevel { high, careful, none, unreadable }

class PosterFlag {
  final String title;
  final String detail;
  final double severity; // 0.0 to 1.0
  final List<int> lines; // indexes of the poster lines to highlight

  const PosterFlag({
    required this.title,
    required this.detail,
    required this.severity,
    required this.lines,
  });
}

class PosterAnalysis {
  final List<PosterFlag> flags;
  final List<String> goodSigns;
  final List<String> phones;
  final List<String> emails;
  final List<String> links;
  final double risk;
  final PosterLevel level;

  /// 0.0 to 1.0: how much of the text looked like real words.
  final double quality;

  /// True when the poster itself uses scam warning wording.
  final bool awareness;

  const PosterAnalysis({
    required this.flags,
    required this.goodSigns,
    required this.phones,
    required this.emails,
    required this.links,
    required this.risk,
    required this.level,
    required this.quality,
    required this.awareness,
  });

  int get riskPercent => (risk * 100).round().clamp(0, 100).toInt();
}

class _Rule {
  final String title;
  final String detail;
  final double severity;
  final RegExp pattern;
  final bool checkNegation;

  _Rule(
      this.title,
      this.detail,
      this.severity,
      List<String> patterns, {
        this.checkNegation = true,
      }) : pattern = RegExp(patterns.join('|'), caseSensitive: false);
}

/// The keyword rules. Each rule joins phrases in several languages.
/// Add your own phrases here. Keep patterns narrow, because a loose phrase
/// creates false alarms on honest posters.
final List<_Rule> _rules = [
  _Rule(
    'Asks for money first',
    'Real employers, embassies and universities do not ask you to pay an agent a fee before you have an offer. Never pay before you have confirmed the offer on the official website.',
    0.75,
    [
      r'(visa|medical|security|joining|processing|protector|file|booking|clearance|courier|document)\s*(fee|fees|charges?|deposit)',
      r'advance\s*(payment|fee|amount)|pay\s*(first|in\s*advance)|pay\s*before\s*(the\s*)?(visa|joining|interview|selection|departure|flight)',
      r'(visa|medical|security|joining|processing|file)\s*(ki\s*)?(fees?|charges?)\s*(pehle|advance|jama)|advance\s*(raqam|paisa)|pehle\s*(paisa|payment|raqam|fees?)|paise?\s*(pehle|advance)',
      r'pag(o|amento)\s*(por\s*adelantado|anticipado|previo|antecipado|adiantado)|pagu?e\s*(primero|por\s*adelantado|primeiro|adiantado)|paiement\s*(d.?avance|anticip.|pr.alable)|payez\s*(d.?abord|d.?avance)',
    ],
  ),
  _Rule(
    'Mentions a fee',
    'Some honest organisations do charge fees, but they are paid only through the official website or office. Check the amount and the payment page there, never from the poster or to an agent.',
    0.25,
    [
      r'(application|admission|enrol+ment|registration|form|document)\s*(fee|fees|charges?)',
    ],
  ),
  _Rule(
    'Payment by wallet, transfer or crypto',
    'The poster points to payment through a mobile wallet, money transfer service, crypto or a personal account. Real organisations give an official invoice and an account in the organisation name.',
    0.8,
    [
      r'(send|transfer|pay|deposit)\b[^.\n]{0,40}(easypaisa|jazzcash|western\s*union|moneygram|bitcoin|usdt|crypto|gift\s*card|personal\s*account)',
    ],
  ),
  _Rule(
    'Guaranteed result',
    'Nobody can honestly guarantee a visa, a job, a scholarship or profits. Those decisions are made by the university, employer or embassy.',
    0.8,
    [
      r'guaranteed?\s*(visa|admission|job|placement|scholarship|income|profit|returns?|selection|success|approval)|visa\s*guarantee|100\s*%\s*(visa|job|admission|success|approval|profit|guarantee|placement)|sure\s*(visa|job|admission|selection)',
      r'(visa|job|naukri|admission)\s*(ki\s*)?(100\s*%\s*)?(guarantee|pakki|pakka)|pakki\s*(job|naukri|visa)',
      r'(visa|empleo|trabajo|admisi.n|beca|visto|emprego)\s*(100\s*%\s*)?garantizad[oa]|garantizamos\s*(tu\s*)?(visa|empleo|trabajo|admisi.n)|(visto|emprego)\s*garantido|(visa|emploi|travail|admission|bourse)\s*garanti(e)?\b|100\s*%\s*garanti',
    ],
  ),
  _Rule(
    'Skips the normal test or interview',
    'Offers that skip the usual test or interview are often used to attract victims. Check the entry rules on the official website of the university or employer.',
    0.55,
    [
      r'(without|no)\s*(ielts|toefl|pte|gre|gmat|sat|entry\s*test|interview)|admission\s*without',
    ],
    checkNegation: false,
  ),
  _Rule(
    'Very high daily earnings',
    'Large daily or weekly earnings for simple work are a classic scam promise.',
    0.7,
    [
      r'earn(?:ing|ings)?\s*(?:up\s*to\s*)?(?:rs\.?|pkr|usd|aed|inr|\$)?\s*\d[\d,]*\s*\+?\s*(?:daily|per\s*day|a\s*day|/\s*day|per\s*hour|weekly|per\s*week)|(?:daily|per\s*day)\s*(?:income|earning|payment|salary)',
      r'(roz|rozana|daily)\s*(kamayein|kamaye|kamao|kamai)|lakhon\s*(kamayein|kamaye|kamao)',
      r'gana\s*(hasta\s*)?\$?\s*\d[\d.,]*\s*(diarios|al\s*d.a|por\s*d.a|semanales|a\s*la\s*semana)|ganhe\s*(at.\s*)?(r\$)?\s*\d[\d.,]*\s*(por\s*dia|di.rios|por\s*semana)|gagnez\s*(jusqu.?.\s*)?\d[\d\s.,]*\s*(€|euros?|\$)?\s*(par\s*jour|/\s*jour|par\s*semaine)',
    ],
  ),
  _Rule(
    'Simple click or typing work',
    'Paid clicking, liking or typing work is a known scam type. The money usually never arrives, or you are asked to pay to join.',
    0.55,
    [
      r'ad\s*click\w*|like\s*(and|&)\s*earn|typing\s*(job|work)|data\s*entry\s*(job|work|from\s*home)|captcha\s*(job|work)',
    ],
  ),
  _Rule(
    'Work from home or online earning offer',
    'Many scams use work from home offers. Check who the company is before you share documents or money.',
    0.4,
    [
      r'earn\s*(from|at)\s*home|online\s*earning|work\s*from\s*home|ghar\s*(baith|beth)\w*|paisa\s*kam\w*|paise\s*kam\w*',
      r'trabaj(a|ando|ar|e)\s*desde\s*(tu\s*)?casa|gana\s*dinero\s*(f.cil|desde\s*casa|r.pido)|trabalhe\s*(de|em)\s*casa|travail\s*(.|a)\s*domicile|gagner\s*de\s*l.?argent\s*(facilement|rapidement)',
    ],
  ),
  _Rule(
    'Investment promise',
    'Promises of fixed or doubled returns, or of earning by recruiting other people, are typical of investment scams.',
    0.78,
    [
      r'(double|triple)\s*(your\s*)?(money|investment)|guaranteed\s*(profit|returns?)|\d+\s*%\s*(daily|weekly|monthly)\s*(profit|returns?|income)?|risk\s*free|passive\s*income|refer\s*(and|&)\s*earn|network\s*marketing|\bmlm\b|pyramid|(forex|crypto|bitcoin|binary|trading)\s*(signals|investment|profit|doubling)',
      r'duplica\s*(tu\s*)?(dinero|inversi.n)|ganancias?\s*garantizadas?|sin\s*riesgo|ingresos?\s*pasivos?|doublez\s*(votre\s*)?(argent|investissement)|gains?\s*garantis?|sans\s*risque|revenus?\s*passifs?|lucro\s*garantido|sem\s*risco',
    ],
  ),
  _Rule(
    'Prize or lottery offer',
    'Prize and lottery posters are a common way to collect fees or personal details. You cannot win a draw you never entered.',
    0.8,
    [
      r'lucky\s*draw|lottery|you\s*(have\s*)?won|claim\s*your\s*(prize|reward|gift)|free\s*(iphone|laptop|car|gift|ticket)\b|prize\s*money',
      r'inaam(i)?\s*(scheme|jeeto|jeetein)|jeeto\s*(inaam|lakh)|aap\s*ne\s*(jeeta|jeet)',
      r'has\s*ganado|ganaste|reclama\s*tu\s*premio|vous\s*avez\s*gagn.|tirage\s*au\s*sort|r.clamez\s*votre\s*(prix|cadeau)|voc.\s*ganhou',
    ],
  ),
  _Rule(
    'Fast or free visa promise',
    'Fast or free visas are rarely real. Visa decisions take time and are made by the embassy, not by an agent.',
    0.6,
    [
      r'visa\s*(in|within)\s*\d+\s*(days?|hours?|weeks?)|\d+\s*days?\s*visa|instant\s*visa|direct\s*visa|free\s*(visa|ticket|flight|accommodation|ielts)|work\s*visa\s*available|visa\s*sale|sponsor(ed)?\s*visa',
    ],
  ),
  _Rule(
    'Loan with no checks',
    'Instant loans with no checks are a common trap. They often ask for a fee before any money arrives.',
    0.75,
    [
      r'(instant|quick|easy|fast)\s*(loan|cash|credit)|loan\s*without\s*(guarantor|document|collateral|cnic|check)|no\s*(credit\s*check|guarantor|collateral)|loan\s*approved\s*in',
    ],
  ),
  _Rule(
    'Very high pay for no experience',
    'Very high pay for no experience is a warning sign. Ask for a written job description and the company details.',
    0.55,
    [
      r'no\s*experience\s*(required|needed|necessary)?[^.\n]{0,40}(high|attractive|handsome|big)\s*(salary|pay|income)|(high|handsome|attractive)\s*(salary|pay|income)[^.\n]{0,40}no\s*experience',
    ],
    checkNegation: false,
  ),
  _Rule(
    'Claims official approval',
    'The poster claims official approval. Confirm it on the website of that organisation, because fake posters copy official names and logos.',
    0.45,
    [
      r'(government|govt\.?|ministry|nadra|hec|fia|embassy|passport\s*office)\s*(approved|authori[sz]ed|registered|recogni[sz]ed|affiliated|sponsored)|(approved|authori[sz]ed|affiliated|sponsored)\s*by\s*(the\s*)?(government|ministry|hec|nadra|embassy)',
    ],
  ),
  _Rule(
    'Pressure to act fast',
    'Pressure to act quickly is used so that you do not stop to check. Honest organisations give you time to verify.',
    0.2,
    [
      r'limited\s*(seats?|time|slots?|offer)|hurry|last\s*(date|chance|seats?)|only\s*\d+\s*(seats?|slots?|vacancies)|few\s*seats|apply\s*(now|today|immediately)|urgent(ly)?\s*(required|hiring|needed|vacancies)|act\s*now|register\s*(now|today)|book\s*now',
      r'jaldi\s*(karein|apply|raabta)|aakhri\s*(date|moqa)',
    ],
  ),
  _Rule(
    'Overseas job or visa offer',
    'Overseas offers are often used in scams. Check that the agent is licensed by your government overseas employment office before you pay anything.',
    0.3,
    [
      r'jobs?\s*(in|abroad)\s*(dubai|saudi|qatar|uae|canada|uk|usa|australia|europe|malaysia|japan|korea)|(dubai|saudi|qatar|canada|uk|europe)\s*(jobs?|visa|work\s*permit)',
    ],
  ),
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Words that cancel a flag when they sit in front of it in the same sentence,
/// for example "we never ask for a visa fee".
final RegExp _negRe = RegExp(
  r"\b(no|not|never|without|zero|nil|cannot|nahi|nahin|bina|sin|sans|jamais|sem|nunca|nada\s*de|free\s*of)\b|don.?t|do\s*n.?t|won.?t|can.?t",
  caseSensitive: false,
);

bool _negatedBefore(String text, int start) {
  final from = start - 40 < 0 ? 0 : start - 40;
  final prefix = text.substring(from, start);
  final sentence = prefix.split(RegExp(r'[.!?;:\n]')).last;
  return _negRe.hasMatch(sentence);
}

bool _hasLiveMatch(_Rule rule, String text) {
  for (final m in rule.pattern.allMatches(text)) {
    if (!rule.checkNegation || !_negatedBefore(text, m.start)) return true;
  }
  return false;
}

/// Returns the matching line indexes, an empty list when the phrase only
/// matched across several lines, or null when the rule did not match.
List<int>? _ruleHits(_Rule rule, List<OcrLine> lines, String flat) {
  final hit = <int>{};
  for (var i = 0; i < lines.length; i++) {
    if (_hasLiveMatch(rule, lines[i].text)) {
      hit.add(i);
      continue;
    }
    if (i + 1 < lines.length && !_hasLiveMatch(rule, lines[i + 1].text)) {
      final joined = '${lines[i].text} ${lines[i + 1].text}';
      if (_hasLiveMatch(rule, joined)) {
        hit.add(i);
        hit.add(i + 1);
      }
    }
  }
  if (hit.isNotEmpty) return hit.toList()..sort();
  if (_hasLiveMatch(rule, flat)) return const [];
  return null;
}

/// A rough guide to how well the text was read: the share of tokens that look
/// like real words, numbers, emails or links. Text in an unsupported script
/// comes out as noise and scores low.
double _readingQuality(String text) {
  final edge = RegExp(r'''^[.,;:!?()\[\]{}"'*\-_]+|[.,;:!?()\[\]{}"'*\-_]+$''');
  final tokens = text
      .split(RegExp(r'\s+'))
      .map((t) => t.replaceAll(edge, ''))
      .where((t) => t.length >= 2)
      .toList();
  if (tokens.isEmpty) return 0;

  final word = RegExp(r'^[a-z][a-z\x27\u2019\-]{1,19}$');
  final vowel = RegExp(r'[aeiouy]');
  final consonants = RegExp(r'[bcdfghjklmnpqrstvwxz]{5,}');
  final number = RegExp(r'^[\d+\-().,/%$€£:]+$');
  final letters = RegExp(r'[a-z]{2,}');

  var good = 0;
  for (final t in tokens) {
    final l = t.toLowerCase();
    if (word.hasMatch(l) && vowel.hasMatch(l) && !consonants.hasMatch(l)) {
      good++;
    } else if (number.hasMatch(l)) {
      good++;
    } else if ((l.contains('@') || l.contains('.')) && letters.hasMatch(l)) {
      good++;
    }
  }
  return good / tokens.length;
}

final RegExp _awarenessRe = RegExp(
  r'(beware|be\s*aware|stay\s*safe|avoid)\W+(?:\w+\W+){0,4}(scams?|fraud\w*|fake\s*\w+|phishing)|(scam|fraud|phishing)\s*(alert|awareness|warning|prevention)|fraud\s*awareness|we\s*never\s*ask|never\s*(pay|share)',
  caseSensitive: false,
);

final RegExp _emailRe = RegExp(
    r'[a-z0-9._%+\-]+@[a-z0-9\-]+(?:\.[a-z0-9\-]+)+',
    caseSensitive: false);
final RegExp _whatsappRe =
RegExp(r'whats\s*app|watsapp|wa\.me|chat\.whatsapp', caseSensitive: false);
final RegExp _addressRe = RegExp(
    r'(street|road|plaza|floor|block|sector|avenue|chowk|colony|town|building|market|mall|boulevard|opposite|house\s*(no|#)|shop\s*(no|#)|office\s*(no|#|\d)|p\.?o\.?\s*box)',
    caseSensitive: false);
final RegExp _licenceRe = RegExp(
    r'(licen[cs]e\s*(no|number|#|:)|reg(istration|d)?\.?\s*(no|number|#)|secp|\bntn\b|\boep\b|\(pvt\)|pvt\.?\s*ltd|private\s*limited|\bllc\b)',
    caseSensitive: false);
final RegExp _institutionalRe = RegExp(
    r'(job|hiring|vacanc|admission|scholarship|visa|university|college|consultan|recruit|immigration|study\s*abroad|overseas|company|loan)',
    caseSensitive: false);
final RegExp _linkRe = RegExp(
    r'(?:https?://|www\.)[^\s,;]+|\b[a-z0-9][a-z0-9\-]*(?:\.[a-z0-9\-]+)*\.(?:com|net|org|pk|info|xyz|top|click|site|online|shop|biz|co|io|me|ly|link|live|vip|app|store|edu|gov)\b(?:/[^\s,;]*)?',
    caseSensitive: false);

const Set<String> _freeMail = {
  'gmail.com',
  'yahoo.com',
  'hotmail.com',
  'outlook.com',
  'live.com',
  'icloud.com',
  'proton.me',
  'protonmail.com',
};

const Set<String> _socialHosts = {
  'facebook.com',
  'fb.com',
  'instagram.com',
  'wa.me',
  't.me',
  'tiktok.com',
  'youtube.com',
  'youtu.be',
  'chat.whatsapp.com',
  'whatsapp.com',
};

List<int> _linesMatching(List<OcrLine> lines, RegExp re) {
  final out = <int>[];
  for (var i = 0; i < lines.length; i++) {
    if (re.hasMatch(lines[i].text)) out.add(i);
  }
  return out;
}

List<String> _findPhones(String text) {
  final out = <String>{};
  for (final m in RegExp(r'\+?\d[\d \-()]{7,}\d').allMatches(text)) {
    final raw = m.group(0)!.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 13) continue;
    if (RegExp(r'^\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}$').hasMatch(raw)) continue;
    out.add(raw.replaceAll(RegExp(r'\s+'), ' '));
  }
  return out.toList();
}

List<String> _findLinks(String text) {
  final out = <String>{};
  for (final m in _linkRe.allMatches(text)) {
    final cleaned = m.group(0)!.replaceAll(RegExp(r'[.,)]+$'), '');
    if (cleaned.length >= 4) out.add(cleaned);
  }
  return out.toList();
}

// ---------------------------------------------------------------------------
// Main entry
// ---------------------------------------------------------------------------

PosterAnalysis analyzePoster(
    List<OcrLine> lines, {
      List<String> qrCodes = const [],
    }) {
  final full = lines.map((l) => l.text).join('\n');
  final lower = full.toLowerCase();
  final flat = full.replaceAll('\n', ' ');
  final chars = full.replaceAll(RegExp(r'\s'), '').length;
  final quality = _readingQuality(full);

  if (chars < 30 && qrCodes.isEmpty) {
    return PosterAnalysis(
      flags: const [],
      goodSigns: const [],
      phones: const [],
      emails: const [],
      links: const [],
      risk: 0,
      level: PosterLevel.unreadable,
      quality: quality,
      awareness: false,
    );
  }

  final flags = <PosterFlag>[];
  final good = <String>[];

  final emails =
  _emailRe.allMatches(lower).map((m) => m.group(0)!).toSet().toList();
  final phones = _findPhones(full);
  final links = _findLinks(lower.replaceAll(_emailRe, ' '));
  final institutional = _institutionalRe.hasMatch(lower);

  // 1. Keyword rules
  for (final rule in _rules) {
    final hit = _ruleHits(rule, lines, flat);
    if (hit != null) {
      flags.add(PosterFlag(
        title: rule.title,
        detail: rule.detail,
        severity: rule.severity,
        lines: hit,
      ));
    }
  }

  // 2. Contact details
  final hasWhatsapp = _whatsappRe.hasMatch(lower);
  final hasAddress = _addressRe.hasMatch(lower);
  final hasLicence = _licenceRe.hasMatch(lower);

  if (hasWhatsapp && !hasAddress && institutional) {
    flags.add(PosterFlag(
      title: 'WhatsApp contact and no office address',
      detail:
      'The poster asks you to reach it through WhatsApp and shows no street address. A real organisation has an office you can find and visit.',
      severity: 0.5,
      lines: _linesMatching(lines, _whatsappRe),
    ));
  } else if (phones.isNotEmpty &&
      !hasAddress &&
      !hasLicence &&
      institutional) {
    flags.add(PosterFlag(
      title: 'No office address visible',
      detail:
      'The poster gives a phone number but no address. This can also be a reading problem, so check that the whole poster was in the photo.',
      severity: 0.3,
      lines: _linesMatching(lines, RegExp(r'\d{7,}')),
    ));
  }

  final freeEmails =
  emails.where((e) => _freeMail.contains(e.split('@').last)).toList();
  if (freeEmails.isNotEmpty && institutional) {
    flags.add(PosterFlag(
      title: 'Free email address',
      detail:
      'An offer from a company, university or agency lists a free email address (${freeEmails.first}). Organisations normally write from their own domain.',
      severity: 0.45,
      lines: _linesMatching(lines, RegExp('@')),
    ));
  }

  // 3. Links
  var allSocial = links.isNotEmpty;
  final ownDomains = <String>[];
  for (final link in links.take(5)) {
    final report = analyzeLink(link);
    if (!report.valid) continue;

    final isSocial = _socialHosts
        .any((s) => report.host == s || report.host.endsWith('.$s'));
    if (!isSocial) {
      allSocial = false;
      ownDomains.add(report.host);
    }

    if (report.worst >= 0.3 && report.findings.isNotEmpty) {
      final first = report.findings.first;
      flags.add(PosterFlag(
        title: 'Suspicious link: ${report.host}',
        detail: '${first.title}. ${first.detail}',
        severity: report.worst > 0.9 ? 0.81 : report.worst * 0.9,
        lines: _linesMatching(lines, RegExp(RegExp.escape(report.host))),
      ));
    }
  }

  if (links.isNotEmpty && allSocial && ownDomains.isEmpty) {
    final ownEmail =
    emails.any((e) => !_freeMail.contains(e.split('@').last));
    if (!ownEmail) {
      flags.add(PosterFlag(
        title: 'Only a social media or chat contact',
        detail:
        'A real organisation normally has its own website. Anyone can open a social media page or chat group in minutes.',
        severity: 0.35,
        lines: _linesMatching(
            lines, RegExp(r'facebook|instagram|wa\.me|t\.me|tiktok|youtube')),
      ));
    }
  }

  // 4. QR codes
  for (final s in analyzeQrCodes(qrCodes, full)) {
    if (s.suspicion >= 0.35) {
      flags.add(PosterFlag(
        title: s.name,
        detail: s.reason,
        severity: s.suspicion > 0.9 ? 0.81 : s.suspicion * 0.9,
        lines: const [],
      ));
    }
  }
  for (final code in qrCodes) {
    final c = code.toLowerCase();
    if (c.contains('chat.whatsapp.com') ||
        c.contains('wa.me') ||
        c.contains('t.me')) {
      flags.add(const PosterFlag(
        title: 'QR code opens a chat',
        detail:
        'A QR code on the poster opens a WhatsApp or Telegram chat. Official organisations rarely run applications or payments in chats.',
        severity: 0.5,
        lines: [],
      ));
      break;
    }
  }

  // 5. Good signs. They never prove anything, so each one says how to check it.
  if (hasLicence) {
    good.add(
        'A registration or licence detail is shown. This only helps if you confirm it in the official register, because fake posters copy numbers.');
  }
  if (hasAddress) {
    good.add(
        'A street style address is shown. Look it up, and visit if you can. Scammers also invent addresses.');
  }
  final ownEmails =
  emails.where((e) => !_freeMail.contains(e.split('@').last)).toList();
  if (ownEmails.isNotEmpty) {
    good.add(
        'The contact email uses its own domain (${ownEmails.first.split('@').last}). Check that this matches the organisation real website.');
  }

  // 6. Overall risk
  flags.sort((a, b) => b.severity.compareTo(a.severity));
  var safe = 1.0;
  for (final f in flags) {
    safe *= (1 - f.severity * 0.85);
  }
  final risk = (1 - safe).clamp(0.0, 0.98).toDouble();

  PosterLevel level;
  if (risk >= 0.6) {
    level = PosterLevel.high;
  } else if (risk >= 0.3) {
    level = PosterLevel.careful;
  } else {
    level = PosterLevel.none;
  }

  // Never say "no red flags" about text that was not really read.
  if (quality < 0.5 && risk < 0.3) {
    level = PosterLevel.unreadable;
  }

  return PosterAnalysis(
    flags: flags,
    goodSigns: good,
    phones: phones,
    emails: emails,
    links: links,
    risk: risk,
    level: level,
    quality: quality,
    awareness: _awarenessRe.hasMatch(lower),
  );
}
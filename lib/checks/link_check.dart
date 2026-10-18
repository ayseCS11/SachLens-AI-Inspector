/// Offline link checks. They look only at the text of the link.
/// They cannot know whether a website is really safe.

class LinkFinding {
  final String title;
  final String detail;
  final double severity; // 0.0 to 1.0

  const LinkFinding({
    required this.title,
    required this.detail,
    required this.severity,
  });
}

class LinkReport {
  final bool valid;
  final String host;
  final String verdict;
  final double worst;
  final List<LinkFinding> findings;

  const LinkReport({
    required this.valid,
    required this.host,
    required this.verdict,
    required this.worst,
    required this.findings,
  });
}

const Set<String> _shorteners = {
  'bit.ly',
  'tinyurl.com',
  't.co',
  'goo.gl',
  'ow.ly',
  'is.gd',
  'buff.ly',
  'rebrand.ly',
  'cutt.ly',
  'shorturl.at',
  'tiny.cc',
};

const Set<String> _riskyTlds = {
  'zip',
  'mov',
  'top',
  'xyz',
  'click',
  'icu',
  'tk',
  'ml',
  'ga',
  'cf',
  'gq',
  'rest',
  'cyou',
  'buzz',
  'sbs',
};

/// Brand name mapped to the official domains we know for it.
const Map<String, List<String>> _brands = {
  'paypal': ['paypal.com'],
  'google': ['google.com', 'google.com.pk'],
  'facebook': ['facebook.com'],
  'instagram': ['instagram.com'],
  'whatsapp': ['whatsapp.com'],
  'microsoft': ['microsoft.com'],
  'apple': ['apple.com'],
  'amazon': ['amazon.com'],
  'netflix': ['netflix.com'],
  'binance': ['binance.com'],
  'jazzcash': ['jazzcash.com.pk'],
  'easypaisa': ['easypaisa.com.pk'],
  'daraz': ['daraz.pk', 'daraz.com.pk'],
  'nadra': ['nadra.gov.pk'],
  'fbr': ['fbr.gov.pk'],
};

const List<String> _urgentWords = [
  'login',
  'verify',
  'secure',
  'update',
  'account',
  'password',
  'otp',
  'bonus',
  'prize',
  'claim',
];

String _normalize(String token) => token
    .replaceAll('0', 'o')
    .replaceAll('1', 'l')
    .replaceAll('3', 'e')
    .replaceAll('5', 's')
    .replaceAll('rn', 'm');

LinkReport _invalid() => const LinkReport(
  valid: false,
  host: '',
  verdict: 'Not a valid link',
  worst: 0,
  findings: [],
);

LinkReport analyzeLink(String raw) {
  var text = raw.trim();
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return _invalid();
  if (!text.contains('://')) text = 'https://$text';

  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return _invalid();

  final host = uri.host.toLowerCase();
  final isIp = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
  if (!host.contains('.') && !isIp) return _invalid();

  final findings = <LinkFinding>[];

  if (uri.scheme == 'http') {
    findings.add(const LinkFinding(
      title: 'Not encrypted',
      detail: 'The link starts with http, not https, so the connection is not protected.',
      severity: 0.4,
    ));
  }

  if (uri.userInfo.isNotEmpty) {
    findings.add(LinkFinding(
      title: 'Hidden destination',
      detail:
      'Text before the @ sign is ignored by browsers. The real site is "$host", not "${uri.userInfo}".',
      severity: 0.85,
    ));
  }

  if (isIp) {
    findings.add(const LinkFinding(
      title: 'Numeric address',
      detail: 'The link uses a number instead of a website name. Real companies rarely do this.',
      severity: 0.7,
    ));
  }

  if (host.contains('xn--')) {
    findings.add(const LinkFinding(
      title: 'Lookalike characters',
      detail: 'The name uses special characters that can imitate a well known site.',
      severity: 0.75,
    ));
  }

  if (_shorteners.contains(host)) {
    findings.add(const LinkFinding(
      title: 'Shortened link',
      detail: 'A shortener hides the real destination. Expand it before you trust it.',
      severity: 0.5,
    ));
  }

  final tld = host.split('.').last;
  if (_riskyTlds.contains(tld)) {
    findings.add(LinkFinding(
      title: 'Unusual ending',
      detail: 'The ending ".$tld" is often used in scams, though many honest sites use it too.',
      severity: 0.4,
    ));
  }

  if (host.split('.').length >= 5) {
    findings.add(const LinkFinding(
      title: 'Many name parts',
      detail: 'A long chain of parts can hide the real owner of the site.',
      severity: 0.4,
    ));
  }

  if ('-'.allMatches(host).length >= 3) {
    findings.add(const LinkFinding(
      title: 'Many hyphens',
      detail: 'Names with many hyphens are common in fake sites.',
      severity: 0.3,
    ));
  }

  // Brand impersonation: uses a famous name but is not the official domain.
  final tokens = host.split(RegExp(r'[.\-]'));
  for (final entry in _brands.entries) {
    final brand = entry.key;
    final isOfficial =
    entry.value.any((d) => host == d || host.endsWith('.$d'));
    if (isOfficial) continue;

    if (tokens.contains(brand)) {
      findings.add(LinkFinding(
        title: 'Uses the name "$brand"',
        detail:
        'This link mentions $brand but is not on its official site (${entry.value.first}).',
        severity: 0.8,
      ));
      break;
    }
    final lookalike = tokens.any((t) => t != brand && _normalize(t) == brand);
    if (lookalike) {
      findings.add(LinkFinding(
        title: 'Lookalike spelling of "$brand"',
        detail:
        'The name imitates $brand with swapped characters. The official site is ${entry.value.first}.',
        severity: 0.85,
      ));
      break;
    }
  }

  if (text.length > 120) {
    findings.add(const LinkFinding(
      title: 'Very long link',
      detail: 'Very long links can hide where they really lead.',
      severity: 0.3,
    ));
  }

  final tail = '${uri.path}?${uri.query}'.toLowerCase();
  final urgent = _urgentWords.where(tail.contains).toList();
  if (urgent.isNotEmpty) {
    findings.add(LinkFinding(
      title: 'Pressure or account words',
      detail:
      'The link contains words such as "${urgent.take(3).join(', ')}", which scams often use.',
      severity: 0.25,
    ));
  }

  findings.sort((a, b) => b.severity.compareTo(a.severity));
  final worst = findings.isEmpty ? 0.0 : findings.first.severity;

  String verdict;
  if (worst >= 0.7) {
    verdict = 'High risk';
  } else if (worst >= 0.3) {
    verdict = 'Be careful';
  } else {
    verdict = 'No warning signs found';
  }

  return LinkReport(
    valid: true,
    host: host,
    verdict: verdict,
    worst: worst,
    findings: findings,
  );
}
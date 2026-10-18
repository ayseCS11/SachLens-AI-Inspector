import '../core/signal.dart';
import 'link_check.dart';
import 'scam_rules.dart' show expectedDomainsFor;

String _short(String s) => s.length > 80 ? '${s.substring(0, 80)}...' : s;

bool _hostMatches(String host, List<String> domains) =>
    domains.any((d) => host == d || host.endsWith('.$d'));

/// Turns the QR codes found in a document into signals.
/// It only reads the text inside each code and never opens anything.
List<Signal> analyzeQrCodes(List<String> codes, String documentText) {
  if (codes.isEmpty) return const [];

  final out = <Signal>[];
  final expected = expectedDomainsFor(documentText.toLowerCase());

  for (final code in codes.take(5)) {
    final c = code.trim();
    final lower = c.toLowerCase();

    // A QR code that asks for a payment
    final isPaymentCode = RegExp(
        r'^(bitcoin|ethereum|litecoin|monero|upi|paypal|venmo|cashapp):')
        .hasMatch(lower) ||
        lower.contains('payto') ||
        lower.contains('iban=');
    if (isPaymentCode) {
      out.add(const Signal(
        name: 'QR payment request',
        suspicion: 0.8,
        weight: 2.5,
        reason:
        'A QR code on this file contains a payment request. Pay only through the official website of the issuer, never through a code on a document.',
      ));
      continue;
    }

    final isLink = lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.');

    if (!isLink) {
      out.add(Signal(
        name: 'QR code',
        suspicion: 0.3,
        weight: 0.5,
        reason:
        'A QR code was found that holds text, not a web link: "${_short(c)}".',
      ));
      continue;
    }

    final report = analyzeLink(c);
    if (!report.valid) {
      out.add(Signal(
        name: 'QR code',
        suspicion: 0.4,
        weight: 1,
        reason: 'A QR code holds something that looks like a link but is not valid: "${_short(c)}".',
      ));
      continue;
    }

    final host = report.host;

    // Compare with the issuer named in the document
    if (expected != null) {
      if (_hostMatches(host, expected)) {
        out.add(Signal(
          name: 'QR matches issuer',
          suspicion: 0.1,
          weight: 1.5,
          reason:
          'The QR code leads to $host, which matches the issuer named in the document. '
              'Scammers can also point a code to a real site, so this proves little about the letter itself.',
        ));
      } else {
        out.add(Signal(
          name: 'QR leads to another site',
          suspicion: 0.9,
          weight: 3,
          reason:
          'The document names an issuer whose official site is ${expected.first}, but its QR code leads to $host. '
              'Do not scan it with a payment or login in mind.',
        ));
      }
    }

    // General warnings about the link text
    if (report.worst >= 0.3) {
      final first = report.findings.first;
      out.add(Signal(
        name: 'QR link warning',
        suspicion: report.worst,
        weight: report.worst >= 0.7 ? 2.5 : 1.5,
        reason: 'The QR code leads to $host. ${first.title}: ${first.detail}',
      ));
    } else if (expected == null) {
      out.add(Signal(
        name: 'QR code',
        suspicion: 0.2,
        weight: 0.5,
        reason:
        'The QR code leads to $host. No warning signs were found in the link text, but SachLens cannot judge the website. '
            'Check that it belongs to the issuer.',
      ));
    }
  }

  return out;
}
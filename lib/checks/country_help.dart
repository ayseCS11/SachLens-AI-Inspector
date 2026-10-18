class CountryHelp {
  final String code;
  final String name;
  final List<String> lines;

  const CountryHelp(this.code, this.name, this.lines);
}

const List<CountryHelp> allCountryHelp = [
  CountryHelp('PK', 'Pakistan', [
    'Licensed overseas job promoters are listed by the Bureau of Emigration and Overseas Employment (beoe.gov.pk). Check the licence number there.',
    'Registered companies are listed by the SECP (secp.gov.pk).',
    'Report online fraud to the FIA National Cyber Crime Reporting Centre (nr3c.gov.pk).',
  ]),
  CountryHelp('IN', 'India', [
    'Report cyber fraud at cybercrime.gov.in or call 1930.',
    'Check companies with the Ministry of Corporate Affairs (mca.gov.in).',
    'For jobs abroad, check the recruiting agent with the Protector General of Emigrants (emigrate.gov.in).',
  ]),
  CountryHelp('US', 'United States', [
    'Report scams to the Federal Trade Commission (reportfraud.ftc.gov) and to the FBI (ic3.gov).',
    'Check a business in your state business registry and with the Better Business Bureau (bbb.org).',
  ]),
  CountryHelp('GB', 'United Kingdom', [
    'Report fraud to the national fraud reporting service (Action Fraud, now being replaced by Report Fraud). In Scotland, call 101.',
    'Check a company at Companies House.',
  ]),
  CountryHelp('CA', 'Canada', [
    'Report scams to the Canadian Anti-Fraud Centre (antifraudcentre-centreantifraude.ca).',
    'Check a business in the federal or provincial corporate registry.',
  ]),
  CountryHelp('AU', 'Australia', [
    'Report scams to Scamwatch (scamwatch.gov.au).',
    'Check a company with ASIC (asic.gov.au).',
  ]),
  CountryHelp('AE', 'United Arab Emirates', [
    'Confirm job offers and any fees with the Ministry of Human Resources and Emiratisation (mohre.gov.ae).',
  ]),
  CountryHelp('NG', 'Nigeria', [
    'Report fraud to the EFCC (efcc.gov.ng).',
    'Check companies in the Corporate Affairs Commission register (cac.gov.ng).',
  ]),
  CountryHelp('BD', 'Bangladesh', [
    'Check overseas job offers and agencies with BMET (bmet.gov.bd).',
  ]),
  CountryHelp('PH', 'Philippines', [
    'Check recruitment agencies with the Department of Migrant Workers (dmw.gov.ph).',
  ]),
];

const CountryHelp _generic = CountryHelp('', 'your country', [
  'Report the poster to your national police cybercrime unit or consumer protection agency.',
  'Check companies in your national company register.',
  'For jobs abroad, check agents with your government overseas employment or labour ministry.',
]);

CountryHelp helpFor(String? countryCode) {
  if (countryCode == null) return _generic;
  for (final c in allCountryHelp) {
    if (c.code == countryCode.toUpperCase()) return c;
  }
  return _generic;
}
/// Maps ISO 3166-1 alpha-2 country codes → local emergency numbers.
/// Covers 24 countries. Fallback: 112 (international standard).
///
/// Usage:
///   final info = CountryEmergency.forCode('IN');
///   print(info.ambulance); // '108'
class CountryEmergency {
  final String countryCode;
  final String countryName;
  final String police;
  final String ambulance;
  final String fire;
  final String general; // The single all-emergencies number (112/911/999…)

  const CountryEmergency({
    required this.countryCode,
    required this.countryName,
    required this.police,
    required this.ambulance,
    required this.fire,
    required this.general,
  });

  // ── Database ─────────────────────────────────────────────────────────────
  static const Map<String, CountryEmergency> _db = {
    // South Asia
    'IN': CountryEmergency(countryCode:'IN', countryName:'India',        police:'100',   ambulance:'108',   fire:'101',  general:'112'),
    'PK': CountryEmergency(countryCode:'PK', countryName:'Pakistan',     police:'15',    ambulance:'115',   fire:'16',   general:'1122'),
    'BD': CountryEmergency(countryCode:'BD', countryName:'Bangladesh',   police:'999',   ambulance:'199',   fire:'199',  general:'999'),
    'NP': CountryEmergency(countryCode:'NP', countryName:'Nepal',        police:'100',   ambulance:'102',   fire:'101',  general:'112'),
    'LK': CountryEmergency(countryCode:'LK', countryName:'Sri Lanka',    police:'119',   ambulance:'110',   fire:'111',  general:'119'),
    // North America
    'US': CountryEmergency(countryCode:'US', countryName:'USA',          police:'911',   ambulance:'911',   fire:'911',  general:'911'),
    'CA': CountryEmergency(countryCode:'CA', countryName:'Canada',       police:'911',   ambulance:'911',   fire:'911',  general:'911'),
    'MX': CountryEmergency(countryCode:'MX', countryName:'Mexico',       police:'911',   ambulance:'911',   fire:'911',  general:'911'),
    // Europe
    'GB': CountryEmergency(countryCode:'GB', countryName:'UK',           police:'999',   ambulance:'999',   fire:'999',  general:'999'),
    'DE': CountryEmergency(countryCode:'DE', countryName:'Germany',      police:'110',   ambulance:'112',   fire:'112',  general:'112'),
    'FR': CountryEmergency(countryCode:'FR', countryName:'France',       police:'17',    ambulance:'15',    fire:'18',   general:'112'),
    'IT': CountryEmergency(countryCode:'IT', countryName:'Italy',        police:'113',   ambulance:'118',   fire:'115',  general:'112'),
    'ES': CountryEmergency(countryCode:'ES', countryName:'Spain',        police:'091',   ambulance:'061',   fire:'080',  general:'112'),
    'RU': CountryEmergency(countryCode:'RU', countryName:'Russia',       police:'102',   ambulance:'103',   fire:'101',  general:'112'),
    // East Asia & Pacific
    'AU': CountryEmergency(countryCode:'AU', countryName:'Australia',    police:'000',   ambulance:'000',   fire:'000',  general:'000'),
    'JP': CountryEmergency(countryCode:'JP', countryName:'Japan',        police:'110',   ambulance:'119',   fire:'119',  general:'110'),
    'CN': CountryEmergency(countryCode:'CN', countryName:'China',        police:'110',   ambulance:'120',   fire:'119',  general:'110'),
    'SG': CountryEmergency(countryCode:'SG', countryName:'Singapore',    police:'999',   ambulance:'995',   fire:'995',  general:'999'),
    'MY': CountryEmergency(countryCode:'MY', countryName:'Malaysia',     police:'999',   ambulance:'999',   fire:'994',  general:'999'),
    // Middle East
    'AE': CountryEmergency(countryCode:'AE', countryName:'UAE',          police:'999',   ambulance:'998',   fire:'997',  general:'999'),
    'SA': CountryEmergency(countryCode:'SA', countryName:'Saudi Arabia', police:'999',   ambulance:'997',   fire:'998',  general:'911'),
    // Africa
    'ZA': CountryEmergency(countryCode:'ZA', countryName:'South Africa', police:'10111', ambulance:'10177', fire:'10177',general:'112'),
    'NG': CountryEmergency(countryCode:'NG', countryName:'Nigeria',      police:'199',   ambulance:'199',   fire:'199',  general:'199'),
    'KE': CountryEmergency(countryCode:'KE', countryName:'Kenya',        police:'999',   ambulance:'999',   fire:'999',  general:'112'),
    // South America
    'BR': CountryEmergency(countryCode:'BR', countryName:'Brazil',       police:'190',   ambulance:'192',   fire:'193',  general:'190'),
    'AR': CountryEmergency(countryCode:'AR', countryName:'Argentina',    police:'101',   ambulance:'107',   fire:'100',  general:'911'),
  };

  // ── Public API ───────────────────────────────────────────────────────────

  /// Looks up the emergency numbers for the given ISO country code.
  /// Falls back to 112 (international) if the country is not in the database.
  static CountryEmergency forCode(String? isoCode) =>
      _db[isoCode?.toUpperCase()] ?? _fallback;

  static const CountryEmergency _fallback = CountryEmergency(
    countryCode: 'XX',
    countryName: 'International',
    police:    '112',
    ambulance: '112',
    fire:      '112',
    general:   '112',
  );

  /// List of all supported countries (for the settings/country picker UI).
  static List<CountryEmergency> get all =>
      _db.values.toList()
        ..sort((a, b) => a.countryName.compareTo(b.countryName));
}

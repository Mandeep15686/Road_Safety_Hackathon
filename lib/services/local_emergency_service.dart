/// Returns Indian emergency helpline numbers.
/// No backend or internet required.
class LocalEmergencyService {
  static const List<Map<String, dynamic>> _services = [
    {'name': 'All-in-one Emergency',         'type': 'emergency', 'phone': '112'},
    {'name': 'Police',                        'type': 'police',    'phone': '100'},
    {'name': 'Fire',                          'type': 'fire',      'phone': '101'},
    {'name': 'Ambulance',                     'type': 'medical',   'phone': '108'},
    {'name': 'Road Accident / Highway',       'type': 'road',      'phone': '1033'},
    {'name': 'Disaster Management',           'type': 'disaster',  'phone': '1078'},
    {'name': 'Women Helpline',                'type': 'women',     'phone': '1091'},
    {'name': 'Women Domestic Abuse',          'type': 'women',     'phone': '181'},
    {'name': 'Child Helpline',                'type': 'child',     'phone': '1098'},
    {'name': 'Railway Enquiry',               'type': 'railway',   'phone': '139'},
    {'name': 'Railway Accident Emergency',    'type': 'railway',   'phone': '1072'},
    {'name': 'Senior Citizen Helpline',       'type': 'senior',    'phone': '14567'},
    {'name': 'AIDS Helpline',                 'type': 'health',    'phone': '1097'},
    {'name': 'Anti Poison',                   'type': 'health',    'phone': '1066'},
    {'name': 'Natural Calamity Relief',       'type': 'disaster',  'phone': '1070'},
  ];

  /// Returns the list of emergency helpline services.
  Future<List<EmergencyHelpline>> getEmergencyHelplines() async {
    return _services.map((s) {
      return EmergencyHelpline(
        name: s['name'], 
        type: s['type'],
        phone: s['phone'],
      );
    }).toList();
  }
}

class EmergencyHelpline {
  final String name, type, phone;
  const EmergencyHelpline({
    required this.name, 
    required this.type, 
    required this.phone,
  });
}

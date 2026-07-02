class MapPin {
  final String id;
  final double lat;
  final double lng;
  final String contaminant;
  final DateTime timestamp;

  const MapPin({
    required this.id,
    required this.lat,
    required this.lng,
    required this.contaminant,
    required this.timestamp,
  });

  static MapPin fromMap(Map<String, dynamic> data) => MapPin(
        id: data['id'] as String? ?? '',
        lat: (data['lat'] as num?)?.toDouble() ?? 0,
        lng: (data['lng'] as num?)?.toDouble() ?? 0,
        contaminant: data['contaminant'] as String? ?? 'Unknown',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (data['timestamp'] as int?) ?? 0,
          isUtc: true,
        ),
      );
}

// Demo pins shown when Firebase is not configured.
List<MapPin> get seedPins {
  final now = DateTime.now();
  return [
    MapPin(id: 'seed1', lat: 39.12254, lng: -77.54222, contaminant: 'FeCl3', timestamp: now.subtract(const Duration(days: 1))),
    MapPin(id: 'seed2', lat: 39.12812, lng: -77.57370, contaminant: 'KNO3', timestamp: now.subtract(const Duration(hours: 5))),
    MapPin(id: 'seed3', lat: 39.16440, lng: -77.55214, contaminant: 'CuCl2 + NiCl2', timestamp: now.subtract(const Duration(days: 2))),
    MapPin(id: 'seed4', lat: 39.16300, lng: -77.54716, contaminant: 'Safe', timestamp: now.subtract(const Duration(hours: 12))),
    MapPin(id: 'seed5', lat: 39.10671, lng: -77.52973, contaminant: 'PbNO3', timestamp: now.subtract(const Duration(days: 3))),
    MapPin(id: 'seed6', lat: 39.11004, lng: -77.52106, contaminant: 'Na(NO3)', timestamp: now.subtract(const Duration(hours: 8))),
    MapPin(id: 'seed7', lat: 39.10755, lng: -77.51754, contaminant: 'Safe', timestamp: now.subtract(const Duration(hours: 2))),
    MapPin(id: 'seed8', lat: 39.13774, lng: -77.59080, contaminant: 'CuCl2', timestamp: now.subtract(const Duration(days: 1))),
    MapPin(id: 'seed9', lat: 39.13824, lng: -77.58867, contaminant: 'NiCl2', timestamp: now.subtract(const Duration(hours: 6))),
    MapPin(id: 'seed10', lat: 39.13949, lng: -77.58748, contaminant: 'KNO3 + Na(NO3)', timestamp: now.subtract(const Duration(hours: 4))),
    MapPin(id: 'seed11', lat: 39.11052, lng: -77.54669, contaminant: 'Pb(NO3) + FeCl3', timestamp: now.subtract(const Duration(days: 2))),
    MapPin(id: 'seed12', lat: 39.1332, lng: -77.5599, contaminant: 'Safe', timestamp: now.subtract(const Duration(hours: 1))),
    MapPin(id: 'seed13', lat: 39.1350, lng: -77.5550, contaminant: 'CuCl2', timestamp: now.subtract(const Duration(hours: 3))),
    MapPin(id: 'seed14', lat: 39.1310, lng: -77.5620, contaminant: 'FeCl3', timestamp: now.subtract(const Duration(hours: 7))),
    MapPin(id: 'seed15', lat: 39.1300, lng: -77.5560, contaminant: 'Safe', timestamp: now.subtract(const Duration(hours: 10))),
    MapPin(id: 'seed16', lat: 39.1360, lng: -77.5640, contaminant: 'NiCl2', timestamp: now.subtract(const Duration(hours: 5))),
  ];
}

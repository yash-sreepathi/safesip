import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/map_pin.dart';

const _collection = 'readings';

class ReadingsRepository {
  bool get _hasFirebase => Firebase.apps.isNotEmpty;

  List<MapPin> _seedPins([String? contaminantFilter]) {
    if (contaminantFilter == null || contaminantFilter.isEmpty) {
      return seedPins;
    }
    return seedPins.where((pin) => pin.contaminant == contaminantFilter).toList();
  }

  Future<void> addReading({
    required double lat,
    required double lng,
    required String contaminant,
  }) async {
    if (!_hasFirebase) {
      throw StateError('Firebase not configured.');
    }

    await FirebaseFirestore.instance.collection(_collection).add({
      'lat': lat,
      'lng': lng,
      'contaminant': contaminant,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<MapPin>> getPins({String? contaminantFilter}) async {
    if (!_hasFirebase) return _seedPins(contaminantFilter);

    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collection)
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();

      var pins = snap.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'];
        return MapPin.fromMap({
          'id': doc.id,
          'lat': data['lat'],
          'lng': data['lng'],
          'contaminant': data['contaminant'],
          'timestamp': timestamp is Timestamp
              ? timestamp.toDate().millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
        });
      }).toList();

      if (contaminantFilter != null && contaminantFilter.isNotEmpty) {
        pins = pins.where((pin) => pin.contaminant == contaminantFilter).toList();
      }
      if (pins.isNotEmpty) return pins;
    } catch (_) {}

    return _seedPins(contaminantFilter);
  }
}

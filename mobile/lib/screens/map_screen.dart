import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';
import '../models/map_pin.dart';
import '../services/readings_repository.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// Sentinel for "All" filter; PopupMenuItem with value: null does not trigger onSelected.
const String _kFilterAll = '__all__';

class _MapScreenState extends State<MapScreen> {
  final Set<Marker> _markers = {};
  String? _selectedContaminantFilter; // null = All (use _kFilterAll in menu)
  List<MapPin> _pins = [];
  final ReadingsRepository _repo = ReadingsRepository();
  static const LatLng _defaultCenter = LatLng(39.1332, -77.5599);
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _resolveInitialPosition();
    _loadPins();
  }

  Future<void> _resolveInitialPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _initialPosition = _defaultCenter);
      return;
    }
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _initialPosition = _defaultCenter);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _initialPosition = LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      if (mounted) setState(() => _initialPosition = _defaultCenter);
    }
  }

  Future<void> _loadPins() async {
    final pins = await _repo.getPins(contaminantFilter: _selectedContaminantFilter);
    if (mounted) {
      setState(() => _pins = pins);
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    _markers
      ..clear()
      ..addAll(_pins.map((pin) {
        final color = _pinColor(pin.contaminant);
        return Marker(
          markerId: MarkerId(pin.id),
          position: LatLng(pin.lat, pin.lng),
          infoWindow: InfoWindow(
            title: pin.contaminant,
            snippet: _formatTime(pin.timestamp),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(_colorToHue(color)),
        );
      }));
    setState(() {});
  }

  double _colorToHue(Color color) {
    if (color == AppColors.pinSafe) return BitmapDescriptor.hueGreen;
    if (color == AppColors.pinCuCl2) return BitmapDescriptor.hueOrange;
    if (color == AppColors.pinFeCl3) return 20;   // brown-ish
    if (color == AppColors.pinKNO3) return BitmapDescriptor.hueViolet;
    if (color == AppColors.pinNaNO3) return 160;  // teal
    if (color == AppColors.pinNiCl2) return BitmapDescriptor.hueMagenta;
    if (color == AppColors.pinPbNO3) return BitmapDescriptor.hueRed;
    if (color == AppColors.pinCuCl2NiCl2) return 220; // dark blue
    if (color == AppColors.pinKNO3NaNO3) return BitmapDescriptor.hueRose;
    if (color == AppColors.pinPbNO3FeCl3) return 30;  // tan/orange
    return BitmapDescriptor.hueOrange;
  }

  Color _pinColor(String contaminant) {
    final c = contaminant.toLowerCase();
    if (c.contains('safe') || c.contains('baseline')) return AppColors.pinSafe;
    if (c == 'cucl2') return AppColors.pinCuCl2;
    if (c == 'fecl3') return AppColors.pinFeCl3;
    if (c == 'kno3') return AppColors.pinKNO3;
    if (c == 'na(no3)') return AppColors.pinNaNO3;
    if (c == 'nicl2') return AppColors.pinNiCl2;
    if (c == 'pbno3') return AppColors.pinPbNO3;
    if (c.contains('cucl2') && c.contains('nicl2')) return AppColors.pinCuCl2NiCl2;
    if (c.contains('kno3') && c.contains('na')) return AppColors.pinKNO3NaNO3;
    if (c.contains('pb') && c.contains('fecl3')) return AppColors.pinPbNO3FeCl3;
    if (c.contains('lead') || c.contains('pb')) return AppColors.pinPbNO3;
    return AppColors.pinContaminant;
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final d = now.difference(t);
    if (d.inDays > 0) return '${d.inDays} day(s) ago';
    if (d.inHours > 0) return '${d.inHours} hour(s) ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final uniqueContaminants = _pins.map((p) => p.contaminant).toSet().toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contamination map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedContaminantFilter ?? _kFilterAll,
            onSelected: (v) {
              setState(() => _selectedContaminantFilter = v == _kFilterAll ? null : v);
              _loadPins();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: _kFilterAll, child: Text('All')),
              ...uniqueContaminants.map(
                (c) => PopupMenuItem(value: c, child: Text(c)),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedContaminantFilter ?? 'All',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.filter_list),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _initialPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition!,
                    zoom: 12,
                  ),
                  markers: _markers,
                  onMapCreated: (_) => _loadPins(),
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                ),
          if (_markers.isEmpty && _pins.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      _selectedContaminantFilter == null
                          ? '${_pins.length} pins'
                          : 'No pins for "$_selectedContaminantFilter"',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

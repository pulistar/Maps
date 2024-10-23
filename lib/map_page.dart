import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LocationData? _currentLocation;
  final Location _locationService = Location();
  List<LatLng> _additionalPoints = [];
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final hasPermission = await _locationService.hasPermission();
    if (hasPermission == PermissionStatus.denied) {
      await _locationService.requestPermission();
    }
    final locationData = await _locationService.getLocation();
    setState(() {
      _currentLocation = locationData;
    });

    // Listen for location changes
    _locationService.onLocationChanged.listen((LocationData result) {
      setState(() {
        _currentLocation = result;
      });
    });
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ubicación Actual"),
          content: Text(
            "Latitud: ${_currentLocation!.latitude}\n"
            "Longitud: ${_currentLocation!.longitude}",
          ),
          actions: [
            TextButton(
              child: const Text("Cerrar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _generateAdditionalPoints() {
    if (_currentLocation != null) {
      setState(() {
        _additionalPoints = [
          LatLng(_currentLocation!.latitude! + 0.01, _currentLocation!.longitude!), // North
          LatLng(_currentLocation!.latitude! - 0.01, _currentLocation!.longitude!), // South
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude! + 0.01), // East
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude! - 0.01), // West
          LatLng(_currentLocation!.latitude! + 0.01, _currentLocation!.longitude! + 0.01), // NE
          LatLng(_currentLocation!.latitude! - 0.01, _currentLocation!.longitude! - 0.01), // SW
        ];
      });
    }
  }

  void _goToCoordinates() {
    final double? latitude = double.tryParse(_latitudeController.text);
    final double? longitude = double.tryParse(_longitudeController.text);

    if (latitude != null && longitude != null) {
      setState(() {
        _currentLocation = LocationData.fromMap({
          'latitude': latitude,
          'longitude': longitude,
        });
        // Mover el mapa a las coordenadas ingresadas
        _mapController.move(LatLng(latitude, longitude), 13.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Mapa')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Latitud',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Longitud',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _goToCoordinates,
                ),
              ],
            ),
          ),
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: LatLng(
                        _currentLocation!.latitude!,
                        _currentLocation!.longitude!,
                      ),
                      zoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(
                              _currentLocation!.latitude!,
                              _currentLocation!.longitude!,
                            ),
                            builder: (ctx) => GestureDetector(
                              onTap: () {
                                _showLocationDialog();
                              },
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ),
                          ..._additionalPoints.map((point) => Marker(
                                width: 80.0,
                                height: 80.0,
                                point: point,
                                builder: (ctx) => const Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await _getLocation();
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _generateAdditionalPoints,
            child: const Icon(Icons.add_location_alt),
          ),
        ],
      ),
    );
  }
}

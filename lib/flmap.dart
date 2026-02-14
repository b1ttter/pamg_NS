//FLMap.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapFl extends StatefulWidget {
  final Function(List<Map<String, dynamic>>)? onLoaded;
  
  const MapFl({super.key, this.onLoaded});

  @override
  MapFlState createState() => MapFlState();
}

// UWAGA: Klasa publiczna (bez _) żeby GlobalKey działał
class MapFlState extends State<MapFl> {
  final MapController mapController = MapController();
  bool _isLoaded = false;
  Map<String, dynamic>? _rawGeoJson;
  List<Map<String, dynamic>> _featureData = [];
  
  // Publiczny getter dla wyszukiwarki
  List<Map<String, dynamic>> get featureData => _featureData;
  
  // Listy dla poszczególnych warstw
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  List<Polygon> _polygons = [];

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  Future<void> _loadGeoJson() async {
    final data = await rootBundle.loadString('assets/geojson/warstwa.geojson');
    final decodedData = jsonDecode(data);
    
    final features = decodedData['features'] as List;
    _featureData = features.map((f) => Map<String, dynamic>.from({
      'geometry': f['geometry'],
      'properties': f['properties'],
    })).toList();
    
    // Parsuj features i stwórz własne obiekty z własnymi stylami
    _parseFeatures(features);
    
    setState(() {
      _rawGeoJson = decodedData;
      _isLoaded = true;
    });
    
    // Powiadom rodzica że dane są gotowe
    widget.onLoaded?.call(_featureData);
  }

  // PUBLICZNA METODA - centrowanie na wybranym obiekcie
  void centerOnFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    final type = geometry['type'];
    
    LatLng center;
    double zoom = 15;
    
    switch (type) {
      case 'Point':
        final coords = geometry['coordinates'];
        center = LatLng(coords[1], coords[0]);
        zoom = 16;
        break;
      case 'LineString':
        final coords = geometry['coordinates'] as List;
        final midIndex = coords.length ~/ 2;
        center = LatLng(coords[midIndex][1], coords[midIndex][0]);
        zoom = 14;
        break;
      case 'Polygon':
        final coords = geometry['coordinates'][0] as List;
        double lat = 0, lng = 0;
        for (var c in coords) {
          lat += c[1];
          lng += c[0];
        }
        center = LatLng(lat / coords.length, lng / coords.length);
        zoom = 14;
        break;
      case 'MultiPolygon':
        final firstPoly = geometry['coordinates'][0][0] as List;
        double lat = 0, lng = 0;
        for (var c in firstPoly) {
          lat += c[1];
          lng += c[0];
        }
        center = LatLng(lat / firstPoly.length, lng / firstPoly.length);
        zoom = 13;
        break;
      default:
        return;
    }
    
    mapController.move(center, zoom);
  }

  void _parseFeatures(List features) {
    for (var feature in features) {
      final geometry = feature['geometry'];
      final properties = feature['properties'] ?? {};
      final type = geometry['type'];

      switch (type) {
        case 'Point':
          _markers.add(_createCustomMarker(geometry, properties));
          break;
        case 'LineString':
          _polylines.add(_createCustomPolyline(geometry, properties));
          break;
        case 'Polygon':
          _polygons.add(_createCustomPolygon(geometry, properties));
          break;
        case 'MultiPolygon':
          _polygons.addAll(_createCustomMultiPolygon(geometry, properties));
          break;
      }
    }
  }

  // TWORZENIE WŁASNYCH MARKERÓW Z CUSTOMOWYM STYLEM
  Marker _createCustomMarker(Map<String, dynamic> geometry, Map<String, dynamic> properties) {
    final coords = geometry['coordinates'];
    final point = LatLng(coords[1], coords[0]);
    
    // Pobierz kolor ze stroke lub użyj domyślnego
    final colorString = properties['stroke'] ?? '#FF0000';
    final color = _parseColor(colorString);
    
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showFeatureInfo(context, properties),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cień
            Icon(
              Icons.location_on,
              size: 40,
              color: Colors.black.withOpacity(0.3),
            ),
            // Główny marker
            Icon(
              Icons.location_on,
              size: 38,
              color: color,
            ),
            // Białe centrum
            Positioned(
              top: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TWORZENIE WŁASNYCH POLYLINE Z CUSTOMOWYM STYLEM
  Polyline _createCustomPolyline(Map<String, dynamic> geometry, Map<String, dynamic> properties) {
    final coords = geometry['coordinates'] as List;
    final points = coords.map((c) => LatLng(c[1], c[0])).toList();
    
    final colorString = properties['stroke'] ?? '#0066FF';
    final color = _parseColor(colorString);
    final width = (properties['stroke-width'] ?? 3).toDouble();
    
    return Polyline(
      points: points,
      color: color,
      strokeWidth: width,
    );
  }

  // TWORZENIE WŁASNYCH POLYGON Z CUSTOMOWYM STYLEM
  Polygon _createCustomPolygon(Map<String, dynamic> geometry, Map<String, dynamic> properties) {
    final coords = geometry['coordinates'][0] as List;
    final points = coords.map((c) => LatLng(c[1], c[0])).toList();
    
    final strokeColorString = properties['stroke'] ?? '#00AA00';
    final fillColorString = properties['fill'] ?? strokeColorString;
    final strokeColor = _parseColor(strokeColorString);
    final fillColor = _parseColor(fillColorString);
    final fillOpacity = properties['fill-opacity'] ?? 0.25;
    final strokeWidth = (properties['stroke-width'] ?? 2).toDouble();
    
    return Polygon(
      points: points,
      color: fillColor.withOpacity(fillOpacity),
      borderColor: strokeColor,
      borderStrokeWidth: strokeWidth,
      isFilled: true,
    );
  }

  // TWORZENIE MULTIPOLYGON
  List<Polygon> _createCustomMultiPolygon(Map<String, dynamic> geometry, Map<String, dynamic> properties) {
    final coordsList = geometry['coordinates'] as List;
    return coordsList.map((coords) {
      final points = (coords[0] as List).map((c) => LatLng(c[1], c[0])).toList();
      
      final strokeColorString = properties['stroke'] ?? '#AA00AA';
      final fillColorString = properties['fill'] ?? strokeColorString;
      final strokeColor = _parseColor(strokeColorString);
      final fillColor = _parseColor(fillColorString);
      final fillOpacity = properties['fill-opacity'] ?? 0.2;
      final strokeWidth = (properties['stroke-width'] ?? 2).toDouble();
      
      return Polygon(
        points: points,
        color: fillColor.withOpacity(fillOpacity),
        borderColor: strokeColor,
        borderStrokeWidth: strokeWidth,
        isFilled: true,
      );
    }).toList();
  }

  // HELPER: Konwersja string hex na Color
  Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) {
      buffer.write('FF'); // Dodaj alpha
      buffer.write(hexString.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _showFeatureInfo(BuildContext context, Map<String, dynamic> properties) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Informacje o obiekcie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (properties['name'] != null) ...[
                const Text(
                  'Nazwa:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(properties['name'].toString()),
                const SizedBox(height: 12),
              ],
              if (properties['layer'] != null) ...[
                const Text(
                  'Typ:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(properties['layer'].toString()),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    for (var feature in _featureData) {
      final geometry = feature['geometry'];
      final properties = feature['properties'] as Map<String, dynamic>;
      
      if (_isPointInFeature(point, geometry)) {
        _showFeatureInfo(context, properties);
        break;
      }
    }
  }

  bool _isPointInFeature(LatLng point, Map<String, dynamic> geometry) {
    final type = geometry['type'];
    
    if (type == 'Point') {
      final coords = geometry['coordinates'];
      final featurePoint = LatLng(coords[1], coords[0]);
      final distance = const Distance().as(LengthUnit.Meter, point, featurePoint);
      return distance < 500;
    } else if (type == 'LineString') {
      final coords = geometry['coordinates'] as List;
      return _isPointNearPolyline(point, coords);
    } else if (type == 'Polygon') {
      final coords = geometry['coordinates'][0] as List;
      return _isPointInPolygon(point, coords);
    } else if (type == 'MultiPolygon') {
      final coordsList = geometry['coordinates'] as List;
      for (var coords in coordsList) {
        if (_isPointInPolygon(point, coords[0] as List)) {
          return true;
        }
      }
    }
    
    return false;
  }

  bool _isPointInPolygon(LatLng point, List coords) {
    int intersectCount = 0;
    for (int i = 0; i < coords.length - 1; i++) {
      final v1 = coords[i];
      final v2 = coords[i + 1];
      if (_rayCastIntersect(point, LatLng(v1[1], v1[0]), LatLng(v2[1], v2[0]))) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  bool _rayCastIntersect(LatLng point, LatLng v1, LatLng v2) {
    if ((v1.latitude > point.latitude) == (v2.latitude > point.latitude)) {
      return false;
    }
    final slope = (v2.longitude - v1.longitude) / (v2.latitude - v1.latitude);
    final x = slope * (point.latitude - v1.latitude) + v1.longitude;
    return x > point.longitude;
  }

  bool _isPointNearPolyline(LatLng point, List coords) {
    const threshold = 100.0;
    for (int i = 0; i < coords.length - 1; i++) {
      final p1 = LatLng(coords[i][1], coords[i][0]);
      final p2 = LatLng(coords[i + 1][1], coords[i + 1][0]);
      final distance = _pointToLineDistance(point, p1, p2);
      if (distance < threshold) {
        return true;
      }
    }
    return false;
  }

  double _pointToLineDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final d = const Distance();
    final lineLength = d.as(LengthUnit.Meter, lineStart, lineEnd);
    if (lineLength == 0) return d.as(LengthUnit.Meter, point, lineStart);
    
    final t = ((point.latitude - lineStart.latitude) * (lineEnd.latitude - lineStart.latitude) +
               (point.longitude - lineStart.longitude) * (lineEnd.longitude - lineStart.longitude)) /
              (lineLength * lineLength);
    
    if (t < 0) return d.as(LengthUnit.Meter, point, lineStart);
    if (t > 1) return d.as(LengthUnit.Meter, point, lineEnd);
    
    final projection = LatLng(
      lineStart.latitude + t * (lineEnd.latitude - lineStart.latitude),
      lineStart.longitude + t * (lineEnd.longitude - lineStart.longitude),
    );
    
    return d.as(LengthUnit.Meter, point, projection);
  }

  @override
  Widget build(context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(52.03, 23.11),
        initialZoom: 12,
        onTap: _handleMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        if (_isLoaded) PolygonLayer(polygons: _polygons),
        if (_isLoaded) PolylineLayer(polylines: _polylines),
        if (_isLoaded) MarkerLayer(markers: _markers),
      ],
    );
  }
}
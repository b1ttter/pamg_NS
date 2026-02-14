import 'package:flutter/material.dart';
import 'package:lab1/rzad.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Pasek extends StatelessWidget implements PreferredSizeWidget {
  final List<Map<String, dynamic>> features;
  final Function(Map<String, dynamic>)? onFeatureSelected;

  const Pasek({
    super.key,
    this.features = const [],
    this.onFeatureSelected,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.lightGreen,
      title: Rzad(
        features: features,
        onFeatureSelected: onFeatureSelected,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () async {
            String layerName = '';
            String layerType = 'punkt';

            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Utwórz nową warstwę'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(labelText: 'Nazwa warstwy'),
                        onChanged: (value) => layerName = value,
                      ),
                      SizedBox(height: 10),
                      DropdownButton<String>(
                        value: layerType,
                        items: [
                          DropdownMenuItem(value: 'punkt', child: Text('Punkt')),
                          DropdownMenuItem(value: 'linia', child: Text('Linia')),
                          DropdownMenuItem(value: 'poligon', child: Text('Poligon')),
                        ],
                        onChanged: (value) {
                          if (value != null) layerType = value;
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('Anuluj'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    ElevatedButton(
                      child: Text('Utwórz warstwę'),
                      onPressed: () async {
                        // Pobranie katalogu aplikacji
                        Directory dir = await getApplicationDocumentsDirectory();
                        File geoFile = File('${dir.path}/warstwa.geojson');

                        Map<String, dynamic> geoJson;

                        // Sprawdź, czy plik istnieje
                        if (await geoFile.exists()) {
                          String content = await geoFile.readAsString();
                          geoJson = jsonDecode(content);
                        } else {
                          // Jeśli pliku nie ma, utwórz nowy FeatureCollection
                          geoJson = {"type": "FeatureCollection", "features": []};
                        }

                        // Dodaj nową warstwę jako Feature z przykładowymi współrzędnymi
                        Map<String, dynamic> newFeature = {
                          "type": "Feature",
                          "properties": {
                            "layer": layerType,
                            "name": layerName,
                            "stroke": "#0066ff",
                            "stroke-width": 3,
                            "fill": layerType == 'poligon' ? "#00aa00" : null,
                            "fill-opacity": layerType == 'poligon' ? 0.25 : null
                          },
                          "geometry": {
                            "type": layerType == 'punkt'
                                ? "Point"
                                : layerType == 'linia'
                                    ? "LineString"
                                    : "Polygon",
                            "coordinates": layerType == 'punkt'
                                ? [0.0, 0.0] // przykładowy punkt
                                : layerType == 'linia'
                                    ? [
                                        [0.0, 0.0],
                                        [0.0, 0.0]
                                      ] // przykładowa linia
                                    : [
                                        [
                                          [0.0, 0.0],
                                          [0.0, 0.0],
                                          [0.0, 0.0],
                                          [0.0, 0.0],
                                          [0.0, 0.0]
                                        ]
                                      ], // przykładowy poligon
                          }
                        };

                        geoJson['features'].add(newFeature);

                        // Zapisz do pliku
                        await geoFile.writeAsString(jsonEncode(geoJson));

                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

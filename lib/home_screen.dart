import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lab1/FLMap.dart';
import 'package:lab1/pasek.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<MapFlState> mapKey = GlobalKey<MapFlState>();
  List<Map<String, dynamic>> _features = [];

  void _onMapLoaded(List<Map<String, dynamic>> features) {
    setState(() => _features = features);
  }

  void _onFeatureSelected(Map<String, dynamic> feature) {
    mapKey.currentState?.centerOnFeature(feature);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Pasek(
        features: _features,
        onFeatureSelected: _onFeatureSelected,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 0, 255, 0),
              Color.fromARGB(255, 0, 0, 0),
            ],
          ),
        ),
        child: MapFl(
          key: mapKey,
          onLoaded: _onMapLoaded,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => FirebaseAuth.instance.signOut(),
        backgroundColor: Colors.red,
        child: const Icon(Icons.logout, color: Colors.white),
      ),
    );
  }
}
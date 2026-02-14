import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}






























































// import 'package:flutter/material.dart';
// import 'package:lab1/flmap.dart';
// import 'package:lab1/pasek.dart';

// void main() {
//   runApp(const MyApp());  // ✅ Uruchom StatefulWidget
// }

// class MyApp extends StatefulWidget {  // ✅ NOWY StatefulWidget!
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   final GlobalKey<MapFlState> mapKey = GlobalKey<MapFlState>();  // ✅ Klucz do mapy!
//   List<Map<String, dynamic>> _features = [];  // ✅ LIFTED STATE - dane tutaj!

//   // ✅ CALLBACK - wywoływany gdy MapFl załaduje dane
//   void _onMapLoaded(List<Map<String, dynamic>> features) {
//     setState(() {
//       _features = features;  // Zapisz dane i przebuduj UI
//     });
//   }

//   // ✅ CALLBACK - wywoływany gdy user wybierze obiekt w Rzad
//   void _onFeatureSelected(Map<String, dynamic> feature) {
//     mapKey.currentState?.centerOnFeature(feature);  // Wywołaj metodę na mapie!
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: MyAppBar(
//           features: _features,  // ✅ Przekaż dane do Pasek → Rzad
//           onFeatureSelected: _onFeatureSelected,  // ✅ Przekaż callback
//         ),
//         body: Container(  // ✅ GradientContainer przeniesiony tutaj (inline)
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Color.fromARGB(255, 123, 189, 243),
//                 Color.fromARGB(255, 0, 0, 0),
//               ],
//             ),
//           ),
//           child: MapFl(
//             key: mapKey,  // ✅ Przypisz GlobalKey
//             onLoaded: _onMapLoaded,  // ✅ Przekaż callback
//           ),
//         ),
//       ),
//     );
//   }
// }




























// import 'package:flutter/material.dart';
// import 'gradientcontainer.dart';
// import 'pasek.dart';


// void main() {
//   runApp(
//     MaterialApp(
//       home: Scaffold(
//         appBar: MyAppBar(),
//         body: GradientContainer(),
//       ),
//     ),
//   );
// }


// AppBar(
//           title: Text1('Okno nawigacji'),
//           centerTitle: true,
//           backgroundColor: const Color.fromARGB(255, 126, 38, 30),
//           actions: <Widget>[
//             IconButton(
//               icon: const Icon(Icons.search),
//               tooltip: 'Wyszukaj',
//               onPressed: () {}, 
//             )
//           ]
//         ),

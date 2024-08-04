import 'package:flutter/material.dart';
import 'package:flutterapp/pages/mainpage.dart';
import 'package:flutterapp/sensors.dart';
import 'package:flutterapp/location.dart';
import 'package:flutterapp/mobiletourism.dart';
// import "./nfc.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Memorable',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        // home: MobileTourismWidget(
        //   uid: 'o7hYM5Rw6fO71Jhm81Lt8sIkeiC3',
        // )
        home: MainPage(),
        // home: LocationPage(),
        );
  }
}

// import 'package:flutter/material.dart';
// import 'pages/slider.dart'; // Add this import

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Memorable',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: MainPage(),
//     );
//   }
// }

// class MainPage extends StatelessWidget {
//   const MainPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const SliderPage()),
//             );
//           },
//           child: const Text('Go to Slider Page'),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutterapp/pages/mainpage.dart';
// import 'package:flutterapp/pages/chatbot.dart';
// import 'package:flutterapp/sensors.dart';
// import "./nfc.dart";

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Memorable',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: ChatbotPage(),
//       routes: {
//         '/chatbot': (context) => ChatbotPage(),
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'view/splash_screen_ui.dart';

void main() async {
  //----- โค้ดติดต่อกับ Supabase โปรเจ็กต์ที่เราจะทำงานด้วย -----
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:'https://pijwksaebnqdvgjscxji.supabase.co',
    publishableKey: 'sb_publishable_haxxrFIGpWOTbvpB5vq_ag_Syou-e9o',
  );
  //----------------------------------------------------

  runApp(
    FlutterRunTrackerApp(),
  );
}

class FlutterRunTrackerApp extends StatelessWidget {
  FlutterRunTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreenUi(),
      theme: ThemeData(
        fontFamily: GoogleFonts.kanit().fontFamily,
      ),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreenUi(),
      theme: ThemeData(
        fontFamily: GoogleFonts.kanit().fontFamily,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'shared/widgets/custom_navbar.dart';
import 'features/home/widgets/home_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const FixItNowApp());
}

class FixItNowApp extends StatelessWidget {
  const FixItNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixItNow',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomNavbar(),
      endDrawer: const MobileAppDrawer(), // 👈 এই ড্রয়ারটি যোগ করা হয়েছে
      body: SingleChildScrollView(
        child: Column(children: const [HomeBanner()]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 ১. ইমপোর্ট করুন

import 'shared/widgets/custom_navbar.dart';
import 'features/home/widgets/home_banner.dart';
import 'features/home/widgets/popular_services_section.dart';
import 'features/home/widgets/top_rated_technicians_section.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 👈 ২. ProviderScope দিয়ে runApp র‍্যাপ করুন
  runApp(const ProviderScope(child: FixItNowApp()));
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
      endDrawer: const MobileAppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            HomeBanner(),
            PopularServicesSection(),
            TopRatedTechniciansSection(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart'; // ADD THIS
import 'constant/app_theme.dart';
import 'utils/app_router.dart';
import 'utils/route_names.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HqDashboardApp());
}

class HqDashboardApp extends StatelessWidget {
  const HqDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Defence HQ Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteNames.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

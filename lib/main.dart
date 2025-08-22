import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/phantom_service.dart';
import 'services/deeplink_handler.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PhantomApp());
}

class PhantomApp extends StatefulWidget {
  const PhantomApp({super.key});

  @override
  State<PhantomApp> createState() => _PhantomAppState();
}

class _PhantomAppState extends State<PhantomApp> {
  late PhantomService _phantomService;
  late DeeplinkHandler _deeplinkHandler;

  @override
  void initState() {
    super.initState();
    _phantomService = PhantomService();
    _deeplinkHandler = DeeplinkHandler();
    _initializeDeeplinks();
  }

  Future<void> _initializeDeeplinks() async {
    await _deeplinkHandler.initialize(_phantomService);
  }

  @override
  void dispose() {
    _deeplinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _phantomService),
      ],
      child: MaterialApp(
        title: 'Phantom Deeplink Demo',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

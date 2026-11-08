import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotificationService.instance.init();
  final state = AppState();
  await state.load();
  runApp(ChangeNotifierProvider.value(value: state, child: const MaeveApp()));
}

class MaeveApp extends StatefulWidget {
  const MaeveApp({super.key});

  @override
  State<MaeveApp> createState() => _MaeveAppState();
}

class _MaeveAppState extends State<MaeveApp> {
  late final router = buildRouter(context.read<AppState>());

  @override
  Widget build(BuildContext context) {
    final dark = context.select<AppState, bool>((s) => s.darkMode);
    return MaterialApp.router(
      title: 'Forme',
      debugShowCheckedModeBanner: false,
      theme: MaeveTheme.light(),
      darkTheme: MaeveTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}

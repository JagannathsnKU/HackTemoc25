import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_preview/device_preview.dart';
import 'blocs/auth_bloc.dart';
import 'screens/login_screen.dart';
import 'screens/ios_conversations_screen.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'theme/ios_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService.initialize();
  
  // Initialize iOS home screen widget
  await WidgetService.initialize();
  WidgetService.setupInteractivity();
  
  runApp(
    DevicePreview(
      enabled: true, // Set to false for production
      builder: (context) => const ReachlyApp(),
    ),
  );
}

class ReachlyApp extends StatelessWidget {
  const ReachlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()),
      ],
      child: MaterialApp(
        title: 'Reachly - Social Context Engine',
        debugShowCheckedModeBanner: false,
        theme: IOSTheme.lightTheme, // 🍎 iOS minimalistic theme!
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          return const IOSConversationsScreen(); // 🍎 iOS minimal design!
        }
        return const LoginScreen();
      },
    );
  }
}


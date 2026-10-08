import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/ai_service.dart';
import '../core/services/app_blocker_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/speech_service.dart';
import '../core/services/voice_service.dart';
import '../data/datasources/productivity_datasource.dart';
import '../data/repositories/productivity_repository.dart';
import '../data/repositories/user_repository.dart';
import '../features/activity/activity_view_model.dart';
import '../features/ai_companion/ai_companion_view_model.dart';
import '../features/focus/focus_view_model.dart';
import '../features/goals/goals_view_model.dart';
import '../features/home/home_view_model.dart';
import '../features/insights/insights_view_model.dart';
import '../features/profile/profile_view_model.dart';
import '../features/routines/routines_view_model.dart';
import '../features/voice/voice_command_handler.dart';
import '../features/voice/voice_command_parser.dart';
import 'theme/app_theme.dart';
import '../features/splash/splash_screen.dart';

class EkagraApp extends StatelessWidget {
  const EkagraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Data Sources & Core Services
    const localDataSource = LocalProductivityDataSource();
    final productivityRepo = DefaultProductivityRepository(dataSource: localDataSource);
    final userRepo = DefaultUserRepository(dataSource: localDataSource);
    final voiceService = DefaultVoiceService();
    final speechService = DefaultSpeechRecognitionService();
    final aiService = DefaultAiService(userRepository: userRepo);
    final notificationService = DefaultNotificationService();

    final commandParser = DefaultVoiceCommandParser(aiService: aiService);

    return MultiProvider(
      providers: [
        // Core Repositories & Services
        Provider<ProductivityRepository>.value(value: productivityRepo),
        Provider<UserRepository>.value(value: userRepo),
        Provider<VoiceService>.value(value: voiceService),
        Provider<SpeechRecognitionService>.value(value: speechService),
        Provider<AiService>.value(value: aiService),
        Provider<NotificationService>.value(value: notificationService),

        // App Blocker & Focus Shield Service
        ChangeNotifierProvider<AppBlockerService>(
          create: (_) => AppBlockerService(repository: productivityRepo),
        ),

        // Focus ViewModel
        ChangeNotifierProxyProvider<AppBlockerService, FocusViewModel>(
          create: (ctx) => FocusViewModel(
            repository: productivityRepo,
            notificationService: notificationService,
            voiceService: voiceService,
            userRepository: userRepo,
          ),
          update: (ctx, blocker, previous) {
            final vm = previous ??
                FocusViewModel(
                  repository: productivityRepo,
                  notificationService: notificationService,
                  voiceService: voiceService,
                  userRepository: userRepo,
                );
            vm.setAppBlockerService(blocker);
            return vm;
          },
        ),

        // Home ViewModel
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => HomeViewModel(
            productivityRepository: productivityRepo,
            userRepository: userRepo,
          ),
        ),

        // Activity ViewModel
        ChangeNotifierProxyProvider<AppBlockerService, ActivityViewModel>(
          create: (ctx) => ActivityViewModel(
            repository: productivityRepo,
            userRepository: userRepo,
          ),
          update: (ctx, blocker, previous) {
            final vm = previous ??
                ActivityViewModel(
                  repository: productivityRepo,
                  userRepository: userRepo,
                );
            vm.appBlockerService = blocker;
            return vm;
          },
        ),

        // Insights ViewModel
        ChangeNotifierProxyProvider<AppBlockerService, InsightsViewModel>(
          create: (_) => InsightsViewModel(
            repository: productivityRepo,
            userRepository: userRepo,
            aiService: aiService,
          ),
          update: (_, blocker, previous) {
            final vm = previous ??
                InsightsViewModel(
                  repository: productivityRepo,
                  userRepository: userRepo,
                  aiService: aiService,
                );
            vm.appBlockerService = blocker;
            return vm;
          },
        ),

        // Goals ViewModel
        ChangeNotifierProvider<GoalsViewModel>(
          create: (_) => GoalsViewModel(repository: productivityRepo),
        ),

        // Routines ViewModel
        ChangeNotifierProvider<RoutinesViewModel>(
          create: (_) => RoutinesViewModel(repository: productivityRepo),
        ),

        // Profile ViewModel
        ChangeNotifierProxyProvider<AppBlockerService, ProfileViewModel>(
          create: (ctx) => ProfileViewModel(
            userRepository: userRepo,
            productivityRepository: productivityRepo,
            voiceService: voiceService,
            aiService: aiService,
          ),
          update: (ctx, blocker, previous) {
            final vm = previous ??
                ProfileViewModel(
                  userRepository: userRepo,
                  productivityRepository: productivityRepo,
                  voiceService: voiceService,
                  aiService: aiService,
                );
            vm.setAppBlockerService(blocker);
            return vm;
          },
        ),

        // AI Companion ViewModel
        ChangeNotifierProxyProvider2<FocusViewModel, AppBlockerService, AiCompanionViewModel>(
          create: (ctx) {
            final focusVm = ctx.read<FocusViewModel>();
            final handler = DefaultVoiceCommandHandler(
              productivityRepository: productivityRepo,
              onStartFocusRequested: (dur, mode) {
                focusVm.startSession(durationMinutes: dur);
              },
              onEndFocusRequested: () {
                focusVm.endSession();
              },
              onPauseFocusRequested: () {
                focusVm.pauseSession();
              },
              onResumeFocusRequested: () {
                focusVm.resumeSession();
              },
            );

            return AiCompanionViewModel(
              aiService: aiService,
              voiceService: voiceService,
              speechService: speechService,
              commandParser: commandParser,
              commandHandler: handler,
              userRepository: userRepo,
              productivityRepository: productivityRepo,
            );
          },
          update: (ctx, focusVm, blocker, previous) {
            if (previous != null) {
              previous.appBlockerService = blocker;
              return previous;
            }
            final handler = DefaultVoiceCommandHandler(
              productivityRepository: productivityRepo,
              onStartFocusRequested: (dur, mode) {
                focusVm.startSession(durationMinutes: dur);
              },
              onEndFocusRequested: () {
                focusVm.endSession();
              },
              onPauseFocusRequested: () {
                focusVm.pauseSession();
              },
              onResumeFocusRequested: () {
                focusVm.resumeSession();
              },
            );

            return AiCompanionViewModel(
              aiService: aiService,
              voiceService: voiceService,
              speechService: speechService,
              commandParser: commandParser,
              commandHandler: handler,
              userRepository: userRepo,
              productivityRepository: productivityRepo,
              appBlockerService: blocker,
            );
          },
        ),
      ],
      child: Consumer<ProfileViewModel>(
        builder: (context, profileVm, child) {
          final isDark = profileVm.user?.isDarkMode ?? true;

          return MaterialApp(
            title: 'Ekagra',
            debugShowCheckedModeBanner: false,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

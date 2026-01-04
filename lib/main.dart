import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/local_storage_service.dart';
import 'data/services/hive_service.dart';
import 'data/repositories/pomodoro_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/stats_repository.dart';
import 'data/repositories/firebase_stats_repository.dart';
import 'data/repositories/firebase_task_repository.dart';
import 'features/pomodoro/presentation/cubit/pomodoro_timer_cubit.dart';
import 'features/tasks/presentation/cubit/task_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/analytics/presentation/cubit/stats_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().init();

  // Initialize Hive
  final hiveService = HiveService();
  await hiveService.init();

  // Initialize repositories
  final pomodoroRepository = PomodoroRepository(hiveService);
  final taskRepository = TaskRepository(hiveService);
  final settingsRepository = SettingsRepository(hiveService);
  final statsRepository = StatsRepository(hiveService);

  // Initialize Firebase repositories
  final firebaseStatsRepository = FirebaseStatsRepository();
  final firebaseTaskRepository = FirebaseTaskRepository();

  // Initialize services
  final localStorageService = LocalStorageService();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: pomodoroRepository),
        RepositoryProvider.value(value: taskRepository),
        RepositoryProvider.value(value: settingsRepository),
        RepositoryProvider.value(value: statsRepository),
        RepositoryProvider.value(value: firebaseStatsRepository),
        RepositoryProvider.value(value: firebaseTaskRepository),
        RepositoryProvider.value(value: localStorageService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                PomodoroTimerCubit(pomodoroRepository, statsRepository),
          ),
          BlocProvider(
            create: (context) => TaskCubit(
              taskRepository,
              firebaseTaskRepository,
              localStorageService,
            ),
          ),
          BlocProvider(create: (context) => SettingsCubit(settingsRepository)),
          BlocProvider(
            create: (context) => StatsCubit(
              statsRepository,
              firebaseStatsRepository,
              localStorageService,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

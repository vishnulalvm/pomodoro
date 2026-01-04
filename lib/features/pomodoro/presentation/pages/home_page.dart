import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/widgets/hue_cycle_background.dart';
import '../../presentation/widgets/pomodoro_timer_view.dart';
import '../../presentation/widgets/analytics_section.dart';
import '../../../tasks/presentation/cubit/task_cubit.dart';
import '../../../analytics/presentation/cubit/stats_cubit.dart';
import '../../../auth/presentation/widgets/email_dialog.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../data/repositories/user_repository.dart';
import '../cubit/pomodoro_timer_cubit.dart';
import '../cubit/pomodoro_timer_state.dart';
import 'package:web/web.dart' as web;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  // Sidebar State
  bool _isSidebarOpen = false;

  final TextEditingController _taskController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isArrowHovered = false;

  late final FirebaseAuthService _authService;
  late final LocalStorageService _localStorageService;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _localStorageService = LocalStorageService();
    final userRepository = UserRepository();
    _authService = FirebaseAuthService(userRepository, _localStorageService);

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });

    // Check if user exists and show email dialog if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowEmailDialog();
    });
  }

  Future<void> _checkAndShowEmailDialog() async {
    try {
      // Check if user exists locally
      final hasUser = await _localStorageService.hasUser();

      if (!hasUser) {
        // User doesn't exist locally, show email dialog
        _showEmailDialog();
      } else {
        // User exists, optionally sign in anonymously in background
        final firebaseUser = _authService.getCurrentFirebaseUser();
        if (firebaseUser == null) {
          await _authService.signInAnonymously();
        }
      }
    } catch (e) {
      print('Error checking user: $e');
      // If error, show dialog to be safe
      _showEmailDialog();
    }
  }

  Future<void> _showEmailDialog() async {
    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => EmailDialog(authService: _authService),
    );

    if (email != null && mounted) {
      print('User registered with email: $email');
      // Reload tasks from Firebase now that user is authenticated
      context.read<TaskCubit>().loadTasks();
      // Reload stats from Firebase
      context.read<StatsCubit>().loadStats();
    }
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      context.read<TaskCubit>().addTask(_taskController.text);
      _taskController.clear();
    }
  }

  bool _isFullScreen = false;

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;

      if (kIsWeb) {
        // Web: Use new package:web Fullscreen API
        if (_isFullScreen) {
          web.document.documentElement?.requestFullscreen();
        } else {
          web.document.exitFullscreen();
        }
      } else {
        // Mobile: Use SystemChrome
        if (_isFullScreen) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HueCycleBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false, // Prevent keyboard from pushing up
          body: Stack(
            children: [
              // Layer 1: Vertical PageView (Snap Effect)
              PageView(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                children: [
                  // Page 1: Timer
                  Center(
                    child: PomodoroTimerView(
                      onOpenSidebar: () {
                        setState(() {
                          _isSidebarOpen = true;
                        });
                      },
                    ),
                  ),
                  // Page 2: Analytics
                  const Center(child: AnalyticsSection()),
                ],
              ),

              // Layer 2: Custom Persistent Sidebar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _isSidebarOpen ? 0 : -300,
                top: 0,
                bottom: 0,
                width: 300,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.1,
                        ), // Glass effect
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 80), // Space for top bar
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "Tasks",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Scrollable Task List
                          Expanded(
                            child: BlocBuilder<TaskCubit, TaskState>(
                              builder: (context, state) {
                                if (state is TaskLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  );
                                }

                                if (state is TaskError) {
                                  return Center(
                                    child: Text(
                                      'Error: ${state.message}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                if (state is TaskLoaded) {
                                  final tasks = state.tasks;

                                  if (tasks.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No tasks yet.\nAdd your first task below!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: tasks.length,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    itemBuilder: (context, index) {
                                      final task = tasks[index];
                                      final isCompleted = task.isCompleted;
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 15,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            onTap: () {
                                              if (task.id != null) {
                                                context
                                                    .read<TaskCubit>()
                                                    .toggleTask(task.id!);
                                              }
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                16.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isCompleted
                                                            ? Colors.greenAccent
                                                            : Colors.white,
                                                        width: 2,
                                                      ),
                                                      color: isCompleted
                                                          ? Colors.greenAccent
                                                          : Colors.transparent,
                                                    ),
                                                    child: isCompleted
                                                        ? const Icon(
                                                            Icons.check,
                                                            size: 16,
                                                            color: Colors.black,
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Expanded(
                                                    child: Text(
                                                      task.title,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        decoration: isCompleted
                                                            ? TextDecoration
                                                                  .lineThrough
                                                            : TextDecoration
                                                                  .none,
                                                        decorationColor:
                                                            Colors.white,
                                                        decorationThickness: 2,
                                                      ),
                                                    ),
                                                  ),
                                                  if (task.pomodoroCount > 0)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${task.pomodoroCount}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }

                                return const SizedBox();
                              },
                            ),
                          ),
                          // Embedded Task Input
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _taskController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: "Add a new task...",
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _addTask(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.white,
                                  ),
                                  onPressed: _addTask,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Layer 3: Top Navigation Bar (hide in fullscreen)
              if (!_isFullScreen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: BlocBuilder<PomodoroTimerCubit, PomodoroTimerState>(
                    builder: (context, state) {
                      final completedPomodoros = state.completedPomodoros;
                      final currentCycle = (completedPomodoros % 4) + 1;
                      final isRestMode = state.isRestMode;

                      return AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        centerTitle: true,
                        title: _currentPage == 0 && !isRestMode
                            ? Text(
                                'Pomodoro $currentCycle/4',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              )
                            : _currentPage == 1
                                ? Text(
                                    'Performance',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  )
                                : null,
                        leading: IconButton(
                          icon: Icon(
                            _isSidebarOpen ? Icons.close : Icons.menu,
                            size: 30,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSidebarOpen = !_isSidebarOpen;
                            });
                          },
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(
                              _isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              size: 30,
                              color: Colors.white,
                            ),
                            onPressed: _toggleFullScreen,
                          ),
                          const SizedBox(width: 10),
                        ],
                      );
                    },
                  ),
                ),

              // Layer 4: Fullscreen Exit Button (show only in fullscreen)
              if (_isFullScreen)
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.fullscreen_exit,
                      size: 32,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFullScreen,
                  ),
                ),

              // Layer 5: Bottom Navigation Arrow
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _isArrowHovered = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _isArrowHovered = false;
                      });
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final targetPage = _currentPage == 0 ? 1 : 0;
                          _pageController.animateToPage(
                            targetPage,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isArrowHovered
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: _isArrowHovered
                                ? Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: AnimatedRotation(
                            turns: _currentPage == 0 ? 0 : 0.5,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

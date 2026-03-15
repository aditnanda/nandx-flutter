import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/pages/lock_screen.dart';
import '../features/smb_connections/presentation/pages/connection_list_page.dart';
import '../shared/widgets/loading_view.dart';
import 'app_theme.dart';
import 'router.dart';

class NandxApp extends ConsumerStatefulWidget {
  const NandxApp({super.key});

  @override
  ConsumerState<NandxApp> createState() => _NandxAppState();
}

class _NandxAppState extends ConsumerState<NandxApp>
    with WidgetsBindingObserver {
  bool _shouldLockOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _shouldLockOnResume = true;
      return;
    }

    if (state == AppLifecycleState.resumed && _shouldLockOnResume) {
      _shouldLockOnResume = false;
      ref.read(authControllerProvider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NANDX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authControllerProvider);

    if (authState.isLoading) {
      return const Scaffold(
          body: LoadingView(message: 'Initializing NANDX...'));
    }

    if (!authState.isAuthenticated) {
      return const LockScreen();
    }

    return const ConnectionListPage();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_sprint/core/router/app_router.dart';
import 'package:smart_sprint/core/theme/app_theme.dart';
import 'package:smart_sprint/core/theme/theme_cubit.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartSprintApp());
}

class SmartSprintApp extends StatelessWidget {
  const SmartSprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    // WorkspaceBloc lives at the app root so every URL route (/t/:id, /w/:id,
    // /profile, /search, ...) inherits it — deep links no longer need a
    // wrapping BlocProvider.value.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => WorkspaceBloc()..add(WorkspaceLoaded())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'SmartSprint',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}

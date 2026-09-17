import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(MyApp(preferences: preferences));
}

// Special feature 3: a custom color for the online status icon.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success});

  final Color success;

  @override
  AppColors copyWith({Color? success}) {
    return AppColors(success: success ?? this.success);
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(success: Color.lerp(success, other.success, t)!);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    // Special feature 2: restore the saved mode when the app starts.
    final saved = widget.preferences.getString('themeMode');
    _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  // Keep the selected theme at the top so the whole app changes.
  Future<void> changeTheme(ThemeMode themeMode) async {
    setState(() {
      _themeMode = themeMode;
    });
    await widget.preferences.setString('themeMode', themeMode.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Theme Lab',
      themeMode: _themeMode,
      // The explicit AnimatedTheme below handles the transition.
      themeAnimationDuration: Duration.zero,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        extensions: const [AppColors(success: Color(0xFF1B5E20))],
        // Special feature 1: generate the palette from a seed color.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
          primary: Colors.blueGrey,
          onPrimary: Colors.white,
          secondary: Colors.amber,
          onSecondary: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        extensions: const [AppColors(success: Color(0xFFC8E6C9))],
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
          primary: Colors.teal,
          onPrimary: Colors.white,
          secondary: Colors.teal,
          onSecondary: Colors.white,
        ),
      ),
      // Special feature 4: animate the theme for the entire screen.
      builder: (context, child) {
        return AnimatedTheme(
          duration: const Duration(milliseconds: 500),
          data: Theme.of(context),
          child: child!,
        );
      },
      home: MyHomePage(changeTheme: changeTheme),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.changeTheme});

  final void Function(ThemeMode) changeTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Theme Lab'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Flutter Theme Lab',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Part 2, tasks 1 and 3: animated badge, lasting 400 ms.
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 220,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.online_prediction,
                    color: Theme.of(context).extension<AppColors>()!.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: Online',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => changeTheme(ThemeMode.light),
                  child: const Text('Light Theme'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => changeTheme(ThemeMode.dark),
                  child: const Text('Dark Theme'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

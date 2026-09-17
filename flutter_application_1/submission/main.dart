import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  // Keep the selected theme at the top so the whole app changes.
  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Theme Lab',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                    color: Theme.of(context).colorScheme.onSecondary,
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

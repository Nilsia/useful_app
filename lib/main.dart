import 'package:flutter/material.dart';
import 'package:useful_app/pages/home_page.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

void main() {
  runApp(const UseFulApp());
}

class UseFulApp extends StatefulWidget {
  const UseFulApp({Key? key}) : super(key: key);

  @override
  State<UseFulApp> createState() => _UseFulAppState();
}

class _UseFulAppState extends State<UseFulApp> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
        light: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
        ),
        dark: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.orange,
        ),
        initial: AdaptiveThemeMode.system,
        builder: (ThemeData theme, ThemeData darkTheme) => MaterialApp(
              home: const HomePage(),
              theme: theme,
              darkTheme: darkTheme,
            ));
  }
}

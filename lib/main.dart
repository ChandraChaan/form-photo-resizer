import 'package:flutter/material.dart';

import 'src/home_page.dart';

void main() => runApp(const FormPhotoResizerApp());

class FormPhotoResizerApp extends StatelessWidget {
  const FormPhotoResizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Photo Resizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E5AC8),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E5AC8),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

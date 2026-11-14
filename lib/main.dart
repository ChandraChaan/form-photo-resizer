import 'package:flutter/material.dart';

import 'src/home_page.dart';
import 'src/look.dart';

void main() => runApp(const FormPhotoResizerApp());

class FormPhotoResizerApp extends StatelessWidget {
  const FormPhotoResizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Photo Resizer',
      debugShowCheckedModeBanner: false,
      theme: Look.light.theme(Brightness.light),
      darkTheme: Look.dark.theme(Brightness.dark),
      home: const HomePage(),
    );
  }
}

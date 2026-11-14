import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_photo_resizer/main.dart';
import 'package:form_photo_resizer/src/home_page.dart';
import 'package:image/image.dart' as img;

void main() {
  testWidgets('start screen fits a phone and presets fill the limits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FormPhotoResizerApp());
    expect(find.text('Choose photo or signature'), findsOneWidget);
    expect(find.text('IBPS photo'), findsOneWidget);

    await tester.tap(find.text('IBPS signature'));
    await tester.pump();
    final max = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Max KB'),
    );
    final w = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Width px'),
    );
    expect(max.controller!.text, '20');
    expect(w.controller!.text, '140');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'with a photo chosen: before and after frames and a Resize button',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final photo = img.Image(width: 120, height: 90);
      img.fill(photo, color: img.ColorRgb8(200, 180, 160));
      final bytes = Uint8List.fromList(img.encodeJpg(photo));

      await tester.pumpWidget(MaterialApp(home: HomePage(initialImage: bytes)));
      await tester.pump();
      expect(find.text('YOUR PHOTO'), findsOneWidget);
      expect(find.text('FOR THE FORM'), findsOneWidget);
      expect(find.text('Resize'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

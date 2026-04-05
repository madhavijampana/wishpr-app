import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wishpr_app/screens/add_contact_screen.dart';
import 'package:wishpr_app/screens/add_phrase_screen.dart';
import 'package:wishpr_app/screens/wishpr_shell.dart';
import 'package:wishpr_app/theme/wishpr_theme.dart';

/// Shell-only harness (no Firebase init). Firestore repos are lazy until signed in.
Widget _shellApp() {
  return MaterialApp(
    theme: WishprTheme.dark,
    home: const WishprShell(),
  );
}

void main() {
  testWidgets('Home hero and navigation to Secret Phrases', (tester) async {
    await tester.pumpWidget(_shellApp());

    expect(find.text('Wishpr'), findsOneWidget);
    expect(find.text('Turn words into action'), findsOneWidget);
    expect(find.text('Start Listening'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);

    await tester.tap(find.text('Phrases'));
    await tester.pumpAndSettle();

    expect(find.text('Secret Phrases'), findsOneWidget);
    expect(find.text('Add Phrase'), findsOneWidget);
    expect(find.text('Sign in required'), findsOneWidget);
    expect(
      find.textContaining('Sign in on the previous screen'),
      findsOneWidget,
    );
  });

  testWidgets('Add Phrase and Add Contact forms open and dismiss', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WishprTheme.dark,
        home: const AddPhraseScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Form), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    final scroll = find.byType(SingleChildScrollView).first;
    await tester.drag(scroll, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Trigger Actions'), findsOneWidget);
    expect(find.text('Send SMS'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: WishprTheme.dark,
        home: const AddContactScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Form), findsOneWidget);
    expect(find.text('Preferred Alert Method'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    await tester.pumpWidget(_shellApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Trusted Contacts'), findsOneWidget);
  });
}

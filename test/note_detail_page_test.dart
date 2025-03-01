import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gakunote/features/notes/presentation/pages/note_detail_page.dart';

void main() {
  testWidgets('NoteDetailPage displays note title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: NoteDetailPage(noteId: '1')));

    // Verify that the note title is displayed.
    expect(find.text('ノート 1'), findsOneWidget);
  });
}
